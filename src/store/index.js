import Vue from 'vue';
import Vuex from 'vuex';
import apiClient from '@/services/api';

Vue.use(Vuex);

// Helper untuk mengekstrak array/object baik jika Laravel membungkusnya dengan key .data maupun tidak
const extractData = (res) => {
  if (!res || !res.data) return null;
  return res.data.data !== undefined ? res.data.data : res.data;
};

const normalizeId = (val) => {
  if (val === null || val === undefined || val === '') return null;
  const num = Number(val);
  return Number.isNaN(num) ? val : num;
};

export default new Vuex.Store({
  state: {
    token: localStorage.getItem('token') || null,
    user: JSON.parse(localStorage.getItem('user') || 'null'),
    platform: 'Offline Store',
    carts: [],
    categories: ['Semua'],
    rawMaterials: [],
    products: [],
    promotions: [],
    orders: [],
    summary: { total_transactions: 0, omzet: 0, pending: 0, canceled: 0 },
    cashflows: [],
    cashflowSummary: { in: 0, out: 0, balance: 0 },
    setting: {
      store_name: 'Memuat Toko...',
      location_store: '',
      contact: '',
      logo_path_url: '',
      tax: 11,
      receipt_width: '58 mm',
      receipt_footer: 'Terima kasih telah berbelanja',
    },
  },
  getters: {
    isAuthenticated: (s) => !!s.token,
    user: (s) => s.user,
    platform: (s) => s.platform,
    carts: (s) => s.carts,
    products: (s) => s.products,
    categories: (s) => s.categories,
    rawMaterials: (s) => s.rawMaterials,
    promotions: (s) => s.promotions,
    orders: (s) => s.orders,
    summary: (s) => s.summary,
    cashflows: (s) => s.cashflows,
    cashflowSummary: (s) => s.cashflowSummary,
    setting: (s) => s.setting,
    totalQuantity: (s) => s.carts.reduce((sum, i) => sum + i.quantity, 0),
    totalPrice: (s) => s.carts.reduce((sum, i) => sum + i.activePrice * i.quantity, 0),
  },
  mutations: {
    SET_AUTH(state, { token, user }) {
      state.token = token;
      state.user = user;
      if (token) {
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(user || {}));
      } else {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    },
    SET_POS_DATA(state, { products, categories, setting, promotions, rawMaterials }) {
      if (Array.isArray(products)) {
        state.products = products.map((p) => {
          const catObj = typeof p.category === 'object' && p.category !== null ? p.category : null;
          const resolvedCategoryId =
            p.category_id !== undefined && p.category_id !== null
              ? normalizeId(p.category_id)
              : (catObj && catObj.id !== undefined ? normalizeId(catObj.id) : null);

          const resolvedCategoryName = catObj && catObj.name
            ? catObj.name
            : (typeof p.category === 'string' && p.category ? p.category : 'Umum');

          const normalizedRecipes = Array.isArray(p.recipes)
            ? p.recipes.map((r) => ({
                ...r,
                raw_material_id:
                  r.raw_material_id !== undefined && r.raw_material_id !== null
                    ? normalizeId(r.raw_material_id)
                    : (r.raw_material && r.raw_material.id !== undefined ? normalizeId(r.raw_material.id) : null),
                qty_needed: Number(r.qty_needed || 0),
              }))
            : [];

          return {
            ...p,
            title: p.title || p.name || '',
            category_id: resolvedCategoryId,
            category: catObj || resolvedCategoryName,
            category_name: resolvedCategoryName,
            recipes: normalizedRecipes,
            price: Number(p.price || 0),
            cost_price: Number(p.cost_price || 0),
            stock: p.stock !== null && p.stock !== undefined ? Number(p.stock) : null,
          };
        });
      }

      if (Array.isArray(categories)) {
        const catNames = categories.map((c) => (typeof c === 'object' && c !== null ? c.name : c)).filter(Boolean);
        state.categories = ['Semua', ...new Set(catNames)];
      }

      if (setting && typeof setting === 'object') {
        state.setting = { ...state.setting, ...setting };
      }

      if (Array.isArray(promotions)) {
        state.promotions = promotions;
      }

      if (Array.isArray(rawMaterials)) {
        state.rawMaterials = rawMaterials.map((rm) => ({
          ...rm,
          id: normalizeId(rm.id),
        }));
      }
    },
    SET_ORDERS(state, orders) {
      state.orders = orders || [];
    },
    SET_ORDER_SUMMARY(state, summary) {
      if (summary) {
        state.summary = summary;
      }
    },
    SET_CASHFLOWS(state, { records, summary }) {
      state.cashflows = records || [];
      if (summary) {
        state.cashflowSummary = summary;
      }
    },
    SET_PLATFORM(state, platform) {
      state.platform = platform;
      state.carts.forEach((c) => {
        const prod = state.products.find((p) => p.id === c.id);
        if (prod) c.activePrice = (prod.platformPrices && prod.platformPrices[platform]) || prod.price;
      });
    },
    ADD_CART(state, product) {
      const activePrice = (product.platformPrices && product.platformPrices[state.platform]) || product.price;
      const existing = state.carts.find((i) => i.id === product.id);
      if (existing) {
        existing.quantity += 1;
      } else {
        state.carts.push({ ...product, activePrice, quantity: 1 });
      }
    },
    REMOVE_CART(state, product) {
      const idx = state.carts.findIndex((i) => i.id === product.id);
      if (idx !== -1) {
        if (state.carts[idx].quantity > 1) state.carts[idx].quantity -= 1;
        else state.carts.splice(idx, 1);
      }
    },
    CLEAR_CART(state) {
      state.carts = [];
    },
    COMPLETE_ORDER(state, order) {
      if (order && Array.isArray(order.items)) {
        order.items.forEach((item) => {
          const prod = state.products.find((p) => p.id === item.id);
          if (!prod) return;
          if ((prod.type === 'Retail' || prod.product_type === 'retail') && prod.stock !== null) {
            prod.stock = Math.max(0, prod.stock - item.quantity);
          } else if ((prod.type === 'Resep' || prod.product_type === 'resep') && prod.recipes) {
            prod.recipes.forEach((r) => {
              const rm = state.rawMaterials.find((m) => normalizeId(m.id) === normalizeId(r.raw_material_id));
              if (rm) rm.stock = Math.max(0, Number((rm.stock - r.qty_needed * item.quantity).toFixed(3)));
            });
          }
        });
      }
      if (order) {
        state.orders.unshift(order);
      }
      state.carts = [];
    },
    UPDATE_STOCK_OPNAME(state, { type, id, actualStock }) {
      if (type === 'product') {
        const p = state.products.find((i) => i.id === id);
        if (p) p.stock = Number(actualStock);
      } else {
        const r = state.rawMaterials.find((i) => normalizeId(i.id) === normalizeId(id));
        if (r) r.stock = Number(actualStock);
      }
    },
    ADD_PRODUCT(state, prod) { if (prod) state.products.push(prod); },
    DELETE_PRODUCT(state, id) { state.products = state.products.filter((p) => p.id !== id); },
    ADD_RAW_MATERIAL(state, rm) { if (rm) state.rawMaterials.push(rm); },
    DELETE_RAW_MATERIAL(state, id) { state.rawMaterials = state.rawMaterials.filter((r) => normalizeId(r.id) !== normalizeId(id)); },
    ADD_CASHFLOW(state, cf) { if (cf) state.cashflows.unshift(cf); },
    DELETE_CASHFLOW(state, id) { state.cashflows = state.cashflows.filter((c) => c.id !== id); },
    ADD_PROMO(state, promo) { if (promo) state.promotions.push(promo); },
    DELETE_PROMO(state, id) { state.promotions = state.promotions.filter((p) => p.id !== id); },
    UPDATE_SETTING(state, payload) { state.setting = { ...state.setting, ...payload }; },
  },
  actions: {
    async login({ commit, dispatch }, credentials) {
      const res = await apiClient.post('/login', credentials);

      const token = res.data.token || res.data.access_token || (res.data.data && res.data.data.token);
      const user = res.data.user || (res.data.data && res.data.data.user) || null;

      if (token) {
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(user || {}));
        commit('SET_AUTH', { token, user });
        await dispatch('fetchPosData');
      }

      return res.data;
    },

    async logout({ commit }) {
      try {
        await apiClient.post('/logout');
      } catch (e) {
        // Abaikan jika token sudah expired di server
      } finally {
        commit('SET_AUTH', { token: null, user: null });
      }
    },

    async fetchPosData({ commit }) {
      const ts = Date.now();
      const [prodRes, catRes, setRes, promoRes, rawRes] = await Promise.all([
        apiClient.get('/products', { params: { _t: ts } }),
        apiClient.get('/categories', { params: { _t: ts } }).catch(() => ({ data: [] })),
        apiClient.get('/settings', { params: { _t: ts } }).catch(() => ({ data: { data: { store_name: 'Toko Kasir', tax: 11 } } })),
        apiClient.get('/promotions', { params: { _t: ts } }).catch(() => ({ data: [] })),
        apiClient.get('/raw-materials', { params: { _t: ts } }).catch(() => ({ data: [] })),
      ]);

      commit('SET_POS_DATA', {
        products: extractData(prodRes) || [],
        categories: extractData(catRes) || [],
        setting: extractData(setRes) || {},
        promotions: extractData(promoRes) || [],
        rawMaterials: extractData(rawRes) || [],
      });
    },

    async submitOrder({ commit }, orderPayload) {
      const res = await apiClient.post('/payment-pos', orderPayload);
      const savedOrder = extractData(res) || orderPayload;
      commit('COMPLETE_ORDER', savedOrder);
      return savedOrder;
    },

    async fetchOrders({ commit }, payload = {}) {
      try {
        const response = await apiClient.get('/orders', { params: { ...payload, _t: Date.now() } });
        commit('SET_ORDERS', response.data.orders);
        commit('SET_ORDER_SUMMARY', response.data.summary);
      } catch (err) {
        console.error('Gagal mengambil data orders:', err);
        throw err;
      }
    },

    async fetchCashflows({ commit }, month = null) {
      const params = month ? { month, _t: Date.now() } : { _t: Date.now() };
      const res = await apiClient.get('/cashflows', { params });
      const extracted = extractData(res);

      if (extracted && extracted.records) {
        commit('SET_CASHFLOWS', { records: extracted.records, summary: extracted.summary });
      } else {
        commit('SET_CASHFLOWS', { records: extracted, summary: null });
      }
    },

    async createProduct({ commit }, payload) {
      const res = await apiClient.post('/products', payload);
      commit('ADD_PRODUCT', extractData(res));
    },
    async removeProduct({ commit }, id) {
      await apiClient.delete(`/products/${id}`);
      commit('DELETE_PRODUCT', id);
    },
    async submitStockOpname({ commit }, { type, id, actualStock }) {
      const endpoint = type === 'product' ? `/products/${id}/opname` : `/raw-materials/${id}/opname`;
      await apiClient.post(endpoint, { actual_stock: actualStock, stock: actualStock });
      commit('UPDATE_STOCK_OPNAME', { type, id, actualStock });
    },
    async createRawMaterial({ commit }, payload) {
      const res = await apiClient.post('/raw-materials', payload);
      commit('ADD_RAW_MATERIAL', extractData(res));
    },
    async removeRawMaterial({ commit }, id) {
      await apiClient.delete(`/raw-materials/${id}`);
      commit('DELETE_RAW_MATERIAL', id);
    },
    async createCashflow({ commit }, payload) {
      const res = await apiClient.post('/cashflows', payload);
      commit('ADD_CASHFLOW', extractData(res));
    },
    async removeCashflow({ commit }, id) {
      await apiClient.delete(`/cashflows/${id}`);
      commit('DELETE_CASHFLOW', id);
    },
    async createPromo({ commit }, payload) {
      const res = await apiClient.post('/promotions', payload);
      commit('ADD_PROMO', extractData(res));
    },
    async removePromo({ commit }, id) {
      await apiClient.delete(`/promotions/${id}`);
      commit('DELETE_PROMO', id);
    },
    async saveSettings({ commit }, payload) {
      const res = await apiClient.post('/settings', payload);
      commit('UPDATE_SETTING', extractData(res) || payload);
    },
  },
});