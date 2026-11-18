<template>
  <v-container fluid class="pa-3 pa-md-5">
    <v-row>
      <!-- Kolom Daftar Produk -->
      <v-col cols="12" md="8">
        <div class="d-flex flex-wrap justify-space-between align-center mb-4">
          <div>
            <h1 class="headline font-weight-bold">Kasir</h1>
            <div class="caption grey--text text--darken-1">{{ setting.store_name }}</div>
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
              @change="$store.commit('SET_PLATFORM',$event)"
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
          class="rounded-xl mb-4"
        ></v-text-field>

        <!-- Kategori Filter -->
        <div class="d-flex flex-wrap mb-4" style="overflow-x: auto; white-space: nowrap;">
          <v-chip
            v-for="cat in categoryNames"
            :key="cat"
            class="mr-2 mb-2 font-weight-medium"
            :color="selectedCategory === cat ? '#0f4c3a' : ($vuetify.theme.dark ? '#1e1e1e' : 'white')"
            :class="{
              'white--text': selectedCategory === cat,
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

        <v-alert v-else-if="errorMessage" type="error" dense outlined class="rounded-lg">
          {{ errorMessage }}
        </v-alert>

        <div v-else-if="filteredProducts.length === 0" class="text-center py-10 grey--text">
          Produk tidak ditemukan.
        </div>

        <!-- Grid Produk Responsif -->
        <v-row v-else dense>
          <v-col v-for="prod in filteredProducts" :key="prod.id" cols="6" sm="4" md="3" class="pa-1">
            <v-card
              flat
              outlined
              class="rounded-xl overflow-hidden product-card"
              :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'"
              :class="isOutOfStock(prod) ? 'opacity-60' : 'cursor-pointer'"
              @click="addToCart(prod)"
            >
              <div class="grey lighten-3 d-flex align-center justify-center position-relative" style="height: 105px; overflow: hidden;">
                <img
                  v-if="prod.cover"
                  :src="prod.cover"
                  alt="Cover"
                  style="width: 100%; height: 100%; object-fit: cover;"
                />
                <span v-else class="title grey--text font-weight-bold">
                  {{ prod.title ? prod.title.charAt(0).toUpperCase() : '?' }}
                </span>

                <v-chip
                  v-if="isRecipe(prod)"
                  x-small
                  color="purple lighten-5"
                  class="purple--text font-weight-bold position-absolute"
                  style="top: 6px; left: 6px;"
                >
                  RESEP
                </v-chip>
                <v-chip
                  v-if="isOutOfStock(prod)"
                  x-small
                  color="red lighten-5"
                  class="red--text font-weight-bold position-absolute"
                  style="top: 6px; right: 6px;"
                >
                  HABIS
                </v-chip>
              </div>

              <div class="pa-2">
                <div class="body-2 font-weight-bold text-truncate">{{ prod.title }}</div>
                <div class="d-flex justify-space-between align-center mt-1">
                  <span class="caption font-weight-bold teal--text text--lighten-2">
                    Rp {{ Number(getDisplayPrice(prod)).toLocaleString('id-ID') }}
                  </span>
                  <span
                    v-if="!isRecipe(prod) && prod.stock !== null"
                    style="font-size: 10px;"
                    :class="prod.stock <= 5 ? 'red--text font-weight-bold' : 'grey--text'"
                  >
                    stok {{ prod.stock }}
                  </span>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <!-- Kolom Sidebar Keranjang -->
      <v-col cols="12" md="4" class="mt-4 mt-md-0">
        <SideBarRight />
      </v-col>
    </v-row>

    <!-- Notifikasi Stok -->
    <v-snackbar v-model="snackbar" timeout="2500" color="red darken-3" top right rounded="lg">
      {{ snackbarText }}
    </v-snackbar>

    <!-- Template Struk Thermal Tersembunyi (Sekarang berada di dalam 1 root template) -->
    <div style="display: none;">
      <div id="InvPckPrint">
        <div id="invoice-POS">
          <center>
            <h3>{{ setting.store_name }}</h3>
            <p>{{ setting.location_store }}<br/>Telp: {{ setting.contact }}</p>
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
            <div>PPN ({{ setting.tax }}%): Rp {{ Number(receiptOrder.tax || 0).toLocaleString('id-ID') }}</div>
            <strong>Total: Rp {{ Number(receiptOrder.total_bill || receiptOrder.total || 0).toLocaleString('id-ID') }}</strong>
          </div>
          <center><p style="margin-top: 8px;">{{ setting.receipt_footer }}</p></center>
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
  }),
  computed: {
    ...mapGetters(['products', 'categories', 'platform', 'setting', 'carts']),
    categoryNames() {
      const names = this.categories.map((c) => (typeof c === 'object' ? c.name : c));
      return names.includes('Semua') ? names : ['Semua', ...names];
    },
    filteredProducts() {
      return this.products.filter((p) => {
        const prodCatName = p.category && typeof p.category === 'object' ? p.category.name : p.category;
        const matchCat = this.selectedCategory === 'Semua' || prodCatName === this.selectedCategory;
        const title = (p.title || '').toLowerCase();
        const sku = (p.sku || '').toLowerCase();
        const keyword = (this.search || '').toLowerCase();
        const matchSearch = title.includes(keyword) || sku.includes(keyword);
        return matchCat && matchSearch;
      });
    },
  },
  async created() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await this.$store.dispatch('fetchPosData');
    } catch (err) {
      if (err.response && err.response.status === 401) {
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
  },
  methods: {
    isRecipe(prod) {
      return (prod.product_type || prod.type || '').toLowerCase() === 'resep';
    },
    isOutOfStock(prod) {
      if (this.isRecipe(prod)) return false;
      return prod.stock !== null && Number(prod.stock) <= 0;
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
    addToCart(prod) {
      if (this.isOutOfStock(prod)) {
        this.snackbarText = `Stok ${prod.title} habis!`;
        this.snackbar = true;
        return;
      }

      if (!this.isRecipe(prod) && prod.stock !== null) {
        const inCart = this.carts.find((c) => c.id === prod.id);
        const currentQty = inCart ? inCart.quantity : 0;
        if (currentQty + 1 > Number(prod.stock)) {
          this.snackbarText = `Stok ${prod.title} hanya tersisa ${prod.stock}.`;
          this.snackbar = true;
          return;
        }
      }

      const activePrice = Number(this.getDisplayPrice(prod));
      this.$store.commit('ADD_CART', { ...prod, activePrice });
    },
    printReceipt() {
      const divToPrint = document.getElementById('InvPckPrint');
      if (!divToPrint) return;
      const width = this.setting.receipt_width === '80 mm' ? '80mm' : '58mm';
      const win = window.open('', '_blank', 'width=340,height=600');
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
.product-card:hover {
  border-color: #0f4c3a !important;
  transform: translateY(-2px);
  transition: all 0.2s ease;
}
.opacity-60 {
  opacity: 0.6;
}
</style>