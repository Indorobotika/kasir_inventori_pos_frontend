<template>
  <v-container fluid class="pa-3 pa-md-5 kasir-page">
    <v-row>
      <!-- Kolom Daftar Produk -->
      <v-col cols="12" md="8">
        <div class="d-flex flex-wrap justify-space-between align-center mb-4 anim-fade-down">
          <div>
            <h1 class="headline font-weight-bold">Kasir</h1>
            <div class="caption grey--text text--darken-1">{{ setting && setting.store_name ? setting.store_name : '' }}</div>
          </div>
          <div style="width: 200px;" class="mt-2 mt-md-0">
            <div class="caption grey--text mb-1">Platform penjualan</div>
            <v-select
              :value="platform"
              :items="['Offline Store', 'Tokopedia', 'Shopee']"
              outlined
              dense
              hide-details
              class="rounded-lg"
              :color="$vuetify.theme.dark ? 'white' : '#0f4c3a'"
              @change="onPlatformChange"
            ></v-select>
          </div>
        </div>

        <v-text-field
          v-model="search"
          prepend-inner-icon="mdi-magnify"
          placeholder="Cari produk atau SKU..."
          outlined
          dense
          clearable
          hide-details
          class="rounded-xl mb-4 anim-fade-down"
          style="animation-delay: 60ms;"
        ></v-text-field>

        <!-- Kategori Filter -->
        <div class="d-flex flex-wrap mb-4 anim-fade-down" style="overflow-x: auto; white-space: nowrap; animation-delay: 110ms;">
          <v-chip
            v-for="cat in categoryNames"
            :key="cat"
            class="mr-2 mb-2 font-weight-medium category-chip"
            :color="selectedCategory === cat ? '#0f4c3a' : ($vuetify.theme.dark ? '#1e1e1e' : 'white')"
            :class="{
              'white--text is-selected': selectedCategory === cat,
              'grey--text text--lighten-2': selectedCategory !== cat && $vuetify.theme.dark,
              'grey--text text--darken-3': selectedCategory !== cat && !$vuetify.theme.dark
            }"
            outlined
            @click="selectedCategory = cat"
          >
            {{ cat }}
          </v-chip>
        </div>

        <div v-if="isLoading" class="text-center py-10">
          <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
          <div class="caption grey--text mt-2">Memuat produk dari server...</div>
        </div>

        <transition name="slide-fade">
          <v-alert v-if="!isLoading && errorMessage" type="error" dense outlined class="rounded-lg">
            {{ errorMessage }}
          </v-alert>
        </transition>

        <div v-if="!isLoading && !errorMessage && filteredProducts.length === 0" class="text-center py-10 grey--text anim-fade-in">
          Produk tidak ditemukan.
        </div>

        <!-- Grid Produk Responsif -->
        <v-row v-else-if="!isLoading && !errorMessage" dense :key="gridAnimationKey">
          <v-col
            v-for="(prod, idx) in filteredProducts"
            :key="prod.id"
            cols="6"
            sm="4"
            md="3"
            class="pa-1 anim-card-enter"
            :style="{ '--delay': Math.min(idx, 12) * 28 + 'ms' }"
          >
            <v-card
              flat
              outlined
              class="rounded-xl overflow-hidden product-card"
              :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'"
              :class="{
                'opacity-60 is-out': isOutOfStock(prod),
                'cursor-pointer is-pressed': !isOutOfStock(prod) && lastClickedId === prod.id,
                'cursor-pointer': !isOutOfStock(prod)
              }"
              @click="addToCart(prod)"
            >
              <div class="grey lighten-3 d-flex align-center justify-center position-relative cover-box" style="height: 105px; overflow: hidden;">
                <img
                  v-if="prod.cover"
                  :src="prod.cover"
                  alt="Cover"
                  class="cover-img"
                  style="width: 100%; height: 100%; object-fit: cover;"
                />
                <span v-else class="title grey--text font-weight-bold">
                  {{ prod.title ? prod.title.charAt(0).toUpperCase() : '?' }}
                </span>

                <v-chip
                  v-if="isRecipe(prod)"
                  x-small
                  :color="$vuetify.theme.dark ? 'purple darken-4' : 'purple lighten-5'"
                  :class="$vuetify.theme.dark ? 'purple--text text--lighten-3' : 'purple--text'"
                  class="font-weight-bold position-absolute"
                  style="top: 6px; left: 6px;"
                >
                  RESEP
                </v-chip>
                <v-chip
                  v-else-if="prod.source_type === 'raw_material'"
                  x-small
                  :color="$vuetify.theme.dark ? 'teal darken-4' : 'teal lighten-5'"
                  :class="$vuetify.theme.dark ? 'teal--text text--lighten-3' : 'teal--text'"
                  class="font-weight-bold position-absolute"
                  style="top: 6px; left: 6px;"
                >
                  BAHAN
                </v-chip>
                <v-chip
                  v-if="isOutOfStock(prod)"
                  x-small
                  :color="$vuetify.theme.dark ? 'red darken-4' : 'red lighten-5'"
                  :class="$vuetify.theme.dark ? 'red--text text--lighten-3' : 'red--text'"
                  class="font-weight-bold position-absolute"
                  style="top: 6px; right: 6px;"
                >
                  HABIS
                </v-chip>
              </div>

              <div class="pa-2">
                <div class="body-2 font-weight-bold text-truncate">{{ prod.title }}</div>
                <div class="d-flex justify-space-between align-center mt-1">
                  <span class="caption font-weight-bold teal--text text--lighten-2 tabular-num">
                    Rp {{ Number(getDisplayPrice(prod)).toLocaleString('id-ID') }}
                  </span>
                  <span
                    v-if="!isRecipe(prod) && prod.stock !== null && prod.stock !== undefined"
                    class="tabular-num"
                    style="font-size: 10px;"
                    :class="Number(prod.stock) <= 5 ? 'red--text font-weight-bold' : 'grey--text'"
                  >
                    stok {{ prod.stock }}{{ prod.source_type === 'raw_material' && prod.unit ? ' ' + prod.unit : '' }}
                  </span>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <!-- Kolom Sidebar Keranjang -->
      <v-col cols="12" md="4" class="mt-4 mt-md-0 anim-fade-up" style="animation-delay: 120ms;">
        <SideBarRight />
      </v-col>
    </v-row>

    <!-- Notifikasi Stok / Cetak -->
    <v-snackbar v-model="snackbar" timeout="2500" :color="snackbarColor" top right rounded="lg">
      {{ snackbarText }}
    </v-snackbar>

    <!-- Template Struk Thermal Tersembunyi -->
    <div style="display: none;">
      <div id="InvPckPrint">
        <div id="invoice-POS">
          <center>
            <h3>{{ setting && setting.store_name ? setting.store_name : '' }}</h3>
            <p>{{ setting && setting.location_store ? setting.location_store : '' }}<br/>Telp: {{ setting && setting.contact ? setting.contact : '-' }}</p>
          </center>
          <hr/>
          <p v-if="receiptOrder">
            No: {{ receiptOrder.invoice_number || receiptOrder.invoice }}<br/>
            Waktu: {{ receiptOrder.time }}<br/>
            Pelanggan: {{ receiptOrder.customer_name || 'Umum' }}<br/>
            Platform: {{ receiptOrder.platform }} · {{ receiptOrder.payment_method || receiptOrder.method }}
          </p>
          <table v-if="receiptOrder" style="width: 100%; font-size: 11px;">
            <tr v-for="item in receiptOrder.items" :key="item.id">
              <td>{{ item.title }} x{{ item.quantity }}</td>
              <td style="text-align: right;">{{ (Number(item.price) * Number(item.quantity)).toLocaleString('id-ID') }}</td>
            </tr>
          </table>
          <hr/>
          <div v-if="receiptOrder" style="font-size: 11px; text-align: right;">
            <div>Subtotal: Rp {{ Number(receiptOrder.subtotal || 0).toLocaleString('id-ID') }}</div>
            <div v-if="Number(receiptOrder.discount_amount || receiptOrder.discount || 0) > 0">
              Diskon: -Rp {{ Number(receiptOrder.discount_amount || receiptOrder.discount).toLocaleString('id-ID') }}
            </div>
            <div v-if="Number(receiptOrder.supplier_sales_tax || 0) > 0">
              Potongan/Pajak {{ receiptOrder.platform }}: -Rp {{ Number(receiptOrder.supplier_sales_tax).toLocaleString('id-ID') }}
            </div>
            <div v-else>
              PPN ({{ setting && setting.tax ? setting.tax : 0 }}%): Rp {{ Number(receiptOrder.tax || 0).toLocaleString('id-ID') }}
            </div>
            <strong>Total: Rp {{ Number(receiptOrder.total_bill || receiptOrder.total || 0).toLocaleString('id-ID') }}</strong>
          </div>
          <center><p style="margin-top: 8px;">{{ setting && setting.receipt_footer ? setting.receipt_footer : '' }}</p></center>
        </div>
      </div>
    </div>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import SideBarRight from '@/components/SideBarRight.vue';

export default {
  name: 'Home',
  components: { SideBarRight },
  data: () => ({
    search: '',
    selectedCategory: 'Semua',
    receiptOrder: null,
    isLoading: false,
    errorMessage: '',
    snackbar: false,
    snackbarText: '',
    snackbarColor: 'red darken-3',
    lastClickedId: null,
    gridNonce: 0,
    _pressTimer: null,
  }),
  computed: {
    ...mapGetters(['products', 'categories', 'platform', 'setting', 'carts']),
    gridAnimationKey() {
      return `${this.selectedCategory}-${this.gridNonce}`;
    },
    categoryNames() {
      const cats = Array.isArray(this.categories) ? this.categories : [];
      const names = cats.map((c) => (typeof c === 'object' ? c.name : c)).filter(Boolean);
      return names.includes('Semua') ? names : ['Semua', ...names];
    },
    filteredProducts() {
      const list = Array.isArray(this.products) ? this.products : [];
      return list.filter((p) => {
        const prodCatName = p.category && typeof p.category === 'object'
          ? p.category.name
          : (p.category_name || p.category);
        const matchCat = this.selectedCategory === 'Semua' || prodCatName === this.selectedCategory;
        const title = (p.title || '').toLowerCase();
        const sku = (p.sku || '').toLowerCase();
        const keyword = (this.search || '').toLowerCase();
        const matchSearch = title.includes(keyword) || sku.includes(keyword);
        return matchCat && matchSearch;
      });
    },
  },
  watch: {
    selectedCategory() {
      this.gridNonce += 1;
    },
  },
  async created() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await this.$store.dispatch('fetchPosData');
      this.gridNonce += 1;
    } catch (err) {
      if (err && err.response && err.response.status === 401) {
        this.$store.commit('SET_AUTH', { token: null, user: null });
      } else {
        this.errorMessage = 'Gagal memuat data produk dari server backend.';
      }
    } finally {
      this.isLoading = false;
    }

    this.$root.$on('trigger-print-invoice', (order) => {
      this.receiptOrder = order;
      this.$nextTick(() => this.printReceipt());
    });
  },
  beforeDestroy() {
    this.$root.$off('trigger-print-invoice');
    if (this._pressTimer) {
      clearTimeout(this._pressTimer);
    }
  },
  methods: {
    onPlatformChange(nextPlatform) {
      this.$store.commit('SET_PLATFORM', nextPlatform);
    },
    isRecipe(prod) {
      return (prod.product_type || prod.type || '').toLowerCase() === 'resep';
    },
    isOutOfStock(prod) {
      if (this.isRecipe(prod)) return false;
      return prod.stock !== null && prod.stock !== undefined && Number(prod.stock) <= 0;
    },
    getDisplayPrice(prod) {
      const prices = prod.platform_prices || prod.platformPrices;
      if (Array.isArray(prices)) {
        const found = prices.find((pp) => pp.platform_name === this.platform);
        if (found) return found.price;
      } else if (prices && typeof prices === 'object' && prices[this.platform]) {
        return prices[this.platform];
      }
      return prod.price;
    },
    triggerPressFeedback(id) {
      this.lastClickedId = id;
      if (this._pressTimer) {
        clearTimeout(this._pressTimer);
      }
      this._pressTimer = setTimeout(() => {
        this.lastClickedId = null;
      }, 170);
    },
    showNotice(text, color = 'red darken-3') {
      this.snackbarText = text;
      this.snackbarColor = color;
      this.snackbar = true;
    },
    addToCart(prod) {
      if (this.isOutOfStock(prod)) {
        this.showNotice(`Stok ${prod.title} habis!`, 'red darken-3');
        return;
      }

      if (!this.isRecipe(prod) && prod.stock !== null && prod.stock !== undefined) {
        const cartList = Array.isArray(this.carts) ? this.carts : [];
        const inCart = cartList.find((c) => c.id === prod.id);
        const currentQty = inCart ? Number(inCart.quantity || 0) : 0;
        if (currentQty + 1 > Number(prod.stock)) {
          this.showNotice(`Stok ${prod.title} hanya tersisa ${prod.stock}.`, 'red darken-3');
          return;
        }
      }

      this.triggerPressFeedback(prod.id);
      const activePrice = Number(this.getDisplayPrice(prod));
      this.$store.commit('ADD_CART', { ...prod, activePrice });
    },
    printReceipt() {
      const divToPrint = document.getElementById('InvPckPrint');
      if (!divToPrint) return;
      const width = this.setting && this.setting.receipt_width === '80 mm' ? '80mm' : '58mm';
      const win = window.open('', '_blank', 'width=340,height=600');
      if (!win) {
        this.showNotice('Popup cetak struk diblokir browser.', 'orange darken-3');
        return;
      }
      win.document.write(`
        <html><head><title>Struk Pembayaran</title>
        <style>
          #invoice-POS { width: ${width}; margin: 0 auto; font-family: monospace; font-size: 11px; }
        </style>
        </head><body>${divToPrint.innerHTML}</body></html>
      `);
      win.document.close();
      win.focus();
      setTimeout(() => { win.print(); win.close(); }, 250);
    },
  },
};
</script>

<style scoped>
.kasir-page {
  overflow-x: hidden;
}

.tabular-num {
  font-variant-numeric: tabular-nums;
}

/* Transisi masuk header & filter */
.anim-fade-down {
  animation: fadeDown 0.4s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-fade-up {
  animation: fadeUp 0.48s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-fade-in {
  animation: fadeIn 0.3s ease both;
}

.anim-card-enter {
  animation: cardPopIn 0.36s cubic-bezier(0.22, 1, 0.36, 1) both;
  animation-delay: var(--delay, 0ms);
}

@keyframes fadeDown {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes cardPopIn {
  from {
    opacity: 0;
    transform: translateY(8px) scale(0.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

/* Chip kategori */
.category-chip {
  transition: transform 0.18s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.18s ease;
}

.category-chip:hover {
  transform: translateY(-1px);
}

.category-chip.is-selected {
  transform: translateY(-1px) scale(1.02);
}

/* Kartu produk: hover lift, zoom halus gambar, dan micro-press saat diklik */
.product-card {
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1), border-color 0.2s ease, box-shadow 0.2s ease;
}

.product-card:not(.is-out):hover {
  border-color: #0f4c3a !important;
  transform: translateY(-3px);
  box-shadow: 0 8px 18px rgba(15, 76, 58, 0.09);
}

.product-card:not(.is-out):active,
.product-card.is-pressed {
  transform: scale(0.96);
  border-color: #0f4c3a !important;
}

.cover-img {
  transition: transform 0.28s cubic-bezier(0.22, 1, 0.36, 1);
}

.product-card:not(.is-out):hover .cover-img {
  transform: scale(1.05);
}

.opacity-60 {
  opacity: 0.6;
}

.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.25s ease;
}

.slide-fade-enter,
.slide-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

@media (prefers-reduced-motion: reduce) {
  .anim-fade-down,
  .anim-fade-up,
  .anim-fade-in,
  .anim-card-enter {
    animation: none !important;
  }
  .category-chip,
  .product-card,
  .cover-img {
    transition: none !important;
  }
}
</style>