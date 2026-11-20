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
  return Number.isNaN(num) ? String(val) : num;
};

const roundQty = (val) => {
  const num = Number(val || 0);
  return Number.isNaN(num) ? 0 : Number(num.toFixed(3));
};

const safeParseUser = () => {
  try {
    const raw = localStorage.getItem('user');
    if (!raw || raw === 'undefined' || raw === 'null') return null;
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
};

export default new Vuex.Store({
  state: {
    token: localStorage.getItem('token') || null,
    user: safeParseUser(),
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
      qris_path_url: '',
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
    totalQuantity: (s) => roundQty(s.carts.reduce((sum, i) => sum + Number(i.quantity || 0), 0)),
    totalPrice: (s) =>
      Math.round(
        s.carts.reduce((sum, i) => sum + Number(i.activePrice !== undefined ? i.activePrice : i.price || 0) * Number(i.quantity || 0), 0)
      ),
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
        state.carts = [];
      }
    },
    SET_POS_DATA(state, { products, categories, setting, promotions, rawMaterials }) {
      let normalizedRawMaterials = [];
      if (Array.isArray(rawMaterials)) {
        normalizedRawMaterials = rawMaterials.map((rm) => ({
          ...rm,
          id: normalizeId(rm.id),
          stock: Number(rm.stock || 0),
          min_stock: Number(rm.min_stock || 0),
          cost_price: Number(rm.cost_price || 0),
          sell_price: Number(rm.sell_price || 0),
          is_sellable: Boolean(rm.is_sellable),
          category_id: rm.category_id !== undefined && rm.category_id !== null ? normalizeId(rm.category_id) : null,
        }));
        state.rawMaterials = normalizedRawMaterials;
      } else {
        normalizedRawMaterials = state.rawMaterials || [];
      }

      let mappedProducts = [];
      if (Array.isArray(products)) {
        mappedProducts = products.map((p) => {
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
            id: normalizeId(p.id),
            source_type: p.source_type || 'product',
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

      const sellableFromMaterials = normalizedRawMaterials
        .filter((rm) => rm.is_sellable)
        .map((rm) => {
          const matchedCat = Array.isArray(categories)
            ? categories.find((c) => typeof c === 'object' && c !== null && normalizeId(c.id) === normalizeId(rm.category_id))
            : null;

          const catObj =
            (rm.category && typeof rm.category === 'object')
              ? rm.category
              : (matchedCat || null);

          const catName =
            (catObj && catObj.name) ||
            'Bahan Dijual';

          return {
            id: 'rm_' + rm.id,
            raw_material_id: rm.id,
            source_type: 'raw_material',
            title: rm.name,
            sku: 'BB-' + rm.id,
            unit: rm.unit || 'pcs',
            product_type: 'retail',
            cover: rm.cover || '',
            category_id: rm.category_id,
            category: catObj || catName,
            category_name: catName,
            cost_price: Number(rm.cost_price || 0),
            price: Number(rm.sell_price || 0),
            stock: Number(rm.stock || 0),
            weight: 0,
            recipes: [],
          };
        });

      if (Array.isArray(products) || Array.isArray(rawMaterials)) {
        state.products = [...mappedProducts, ...sellableFromMaterials];
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
    },
    SET_ORDERS(state, orders) {
      state.orders = Array.isArray(orders) ? orders : [];
    },
    SET_ORDER_SUMMARY(state, summary) {
      if (summary && typeof summary === 'object') {
        state.summary = { ...state.summary, ...summary };
      }
    },
    SET_CASHFLOWS(state, { records, summary }) {
      state.cashflows = Array.isArray(records) ? records : [];
      if (summary && typeof summary === 'object') {
        state.cashflowSummary = { ...state.cashflowSummary, ...summary };
      }
    },
    SET_PLATFORM(state, platform) {
      state.platform = platform;
      state.carts.forEach((c) => {
        const prod = state.products.find((p) => p.id === c.id);
        if (prod) {
          const prices = prod.platform_prices || prod.platformPrices;
          if (Array.isArray(prices)) {
            const found = prices.find((pp) => pp.platform_name === platform);
            c.activePrice = found ? Number(found.price) : Number(prod.price || 0);
          } else if (prices && typeof prices === 'object' && prices[platform] !== undefined) {
            c.activePrice = Number(prices[platform]);
          } else {
            c.activePrice = Number(prod.price || 0);
          }
        }
      });
    },
    ADD_CART(state, product) {
      const prices = product.platform_prices || product.platformPrices;
      let platformPrice = product.activePrice !== undefined ? product.activePrice : product.price;
      if (Array.isArray(prices)) {
        const found = prices.find((pp) => pp.platform_name === state.platform);
        if (found) platformPrice = found.price;
      } else if (prices && typeof prices === 'object' && prices[state.platform] !== undefined) {
        platformPrice = prices[state.platform];
      }

      const activePrice = Number(platformPrice || 0);
      const existing = state.carts.find((i) => i.id === product.id);
      if (existing) {
        existing.quantity = roundQty(Number(existing.quantity || 0) + 1);
        existing.activePrice = activePrice;
      } else {
        state.carts.push({ ...product, activePrice, quantity: 1 });
      }
    },
    REMOVE_CART(state, product) {
      const idx = state.carts.findIndex((i) => i.id === product.id);
      if (idx !== -1) {
        const nextQty = roundQty(Number(state.carts[idx].quantity || 0) - 1);
        if (nextQty > 0) state.carts[idx].quantity = nextQty;
        else state.carts.splice(idx, 1);
      }
    },
    CLEAR_CART(state) {
      state.carts = [];
    },
    COMPLETE_ORDER(state, order) {
      if (order && Array.isArray(order.items)) {
        order.items.forEach((item) => {
          const qty = Number(item.quantity || 0);
          const isRm =
            item.source_type === 'raw_material' ||
            Boolean(item.raw_material_id) ||
            String(item.id || '').indexOf('rm_') === 0;

          if (isRm) {
            const rmId = normalizeId(
              item.raw_material_id || String(item.id || '').replace(/^rm_/, '')
            );
            const rm = state.rawMaterials.find((m) => normalizeId(m.id) === rmId);
            if (rm) {
              rm.stock = Math.max(0, roundQty(Number(rm.stock || 0) - qty));
            }
            const virtualProd = state.products.find((p) => p.id === 'rm_' + rmId || p.id === item.id);
            if (virtualProd && virtualProd.stock !== null && virtualProd.stock !== undefined) {
              virtualProd.stock = Math.max(0, roundQty(Number(virtualProd.stock || 0) - qty));
            }
            return;
          }

          const prod = state.products.find((p) => p.id === item.id);
          if (!prod) return;
          if ((prod.type === 'Retail' || prod.product_type === 'retail') && prod.stock !== null && prod.stock !== undefined) {
            prod.stock = Math.max(0, roundQty(Number(prod.stock || 0) - qty));
          } else if ((prod.type === 'Resep' || prod.product_type === 'resep') && Array.isArray(prod.recipes)) {
            prod.recipes.forEach((r) => {
              const rm = state.rawMaterials.find((m) => normalizeId(m.id) === normalizeId(r.raw_material_id));
              if (rm) rm.stock = Math.max(0, roundQty(Number(rm.stock || 0) - Number(r.qty_needed || 0) * qty));
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
        const vp = state.products.find((p) => p.source_type === 'raw_material' && normalizeId(p.raw_material_id) === normalizeId(id));
        if (vp) vp.stock = Number(actualStock);
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
    UPDATE_SETTING(state, payload) {
      if (payload && typeof payload === 'object') {
        state.setting = { ...state.setting, ...payload };
      }
    },
  },
  actions: {
    async login({ commit, dispatch }, credentials) {
      const res = await apiClient.post('/login', credentials);
      const body = (res && res.data) || {};

      const token = body.token || body.access_token || (body.data && body.data.token);
      const user = body.user || (body.data && body.data.user) || null;

      if (token) {
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(user || {}));
        commit('SET_AUTH', { token, user });
        await dispatch('fetchPosData');
      }

      return body;
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

    async submitOrder({ commit, state }, orderPayload) {
      const payloadWithItems = {
        ...orderPayload,
        items: orderPayload && Array.isArray(orderPayload.items) ? orderPayload.items : state.carts,
      };
      const res = await apiClient.post('/payment-pos', payloadWithItems);
      const extracted = extractData(res) || {};
      const savedOrder = {
        ...payloadWithItems,
        ...extracted,
        items: extracted.items || payloadWithItems.items || [],
      };
      commit('COMPLETE_ORDER', savedOrder);
      return savedOrder;
    },

    async fetchOrders({ commit }, payload = {}) {
      try {
        const response = await apiClient.get('/orders', { params: { ...payload, _t: Date.now() } });
        const rawData = (response && response.data) || {};
        const nested = extractData(response);
        const container = (nested && typeof nested === 'object' && !Array.isArray(nested)) ? nested : rawData;

        const ordersList = container.orders || rawData.orders || (Array.isArray(nested) ? nested : []);
        const summaryObj = container.summary || rawData.summary || null;

        commit('SET_ORDERS', ordersList);
        if (summaryObj) {
          commit('SET_ORDER_SUMMARY', summaryObj);
        }
      } catch (err) {
        console.error('Gagal mengambil data orders:', err);
        throw err;
      }
    },

    async fetchCashflows({ commit }, month = null) {
      const params = month ? { month, _t: Date.now() } : { _t: Date.now() };
      const res = await apiClient.get('/cashflows', { params });
      const extracted = extractData(res);

      if (extracted && !Array.isArray(extracted) && extracted.records) {
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