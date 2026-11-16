<template>
  <v-container fluid class="pa-5">
    <v-row>
      <v-col cols="12" md="8">
        <div class="d-flex justify-space-between align-center mb-4">
          <div>
            <h1 class="headline font-weight-bold">Kasir</h1>
            <div class="caption grey--text text--darken-1">{{ setting.store_name }}</div>
          </div>
          <div style="width: 220px;">
            <div class="caption grey--text mb-1">Platform penjualan</div>
            <v-select
              :value="platform"
              :items="['Offline Store', 'Tokopedia', 'Shopee']"
              outlined
              dense
              hide-details
              class="rounded-lg white"
              @change="$store.commit('SET_PLATFORM', $event)"
            ></v-select>
          </div>
        </div>

        <v-text-field
          v-model="search"
          prepend-inner-icon="mdi-magnify"
          placeholder="Cari produk atau SKU..."
          outlined
          dense
          hide-details
          class="rounded-xl white mb-4"
        ></v-text-field>

        <div class="d-flex flex-wrap mb-4">
          <v-chip
            v-for="cat in categories"
            :key="cat"
            class="mr-2 mb-2 font-weight-medium"
            :color="selectedCategory === cat ? '#0f4c3a' : 'white'"
            :dark="selectedCategory === cat"
            outlined
            @click="selectedCategory = cat"
          >
            {{ cat }}
          </v-chip>
        </div>

        <!-- Indikator Loading saat mengambil data dari backend -->
        <div v-if="isLoading" class="text-center py-10">
          <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
          <div class="caption grey--text mt-2">Memuat produk dari server...</div>
        </div>

        <!-- Alert jika terjadi error (misal sesi habis / server mati) -->
        <v-alert v-else-if="errorMessage" type="error" dense outlined class="rounded-lg">
          {{ errorMessage }}
        </v-alert>

        <!-- Pesan jika produk kosong -->
        <div v-else-if="filteredProducts.length === 0" class="text-center py-10 grey--text">
          Produk tidak ditemukan.
        </div>

        <!-- Grid Daftar Produk dari Database -->
        <v-row v-else>
          <v-col v-for="prod in filteredProducts" :key="prod.id" cols="12" sm="6" md="4">
            <v-card flat outlined class="rounded-xl overflow-hidden cursor-pointer product-card white" @click="$store.commit('ADD_CART', prod)">
              <div class="grey lighten-3 d-flex align-center justify-center position-relative" style="height: 155px;">
                <v-chip
                  v-if="prod.type === 'Resep'"
                  x-small
                  color="white"
                  class="font-weight-bold position-absolute"
                  style="top: 10px; left: 10px;"
                >
                  RESEP
                </v-chip>
                <span class="headline grey--text font-weight-bold">{{ prod.title ? prod.title.charAt(0).toUpperCase() : '?' }}</span>
              </div>
              <div class="pa-3">
                <div class="subtitle-2 font-weight-bold text-truncate">{{ prod.title }}</div>
                <div class="d-flex justify-space-between align-center mt-2">
                  <span class="subtitle-2 font-weight-bold teal--text text--darken-4">
                    Rp {{ Number(getDisplayPrice(prod)).toLocaleString('id-ID') }}
                  </span>
                  <span v-if="prod.stock !== null" class="caption grey--text">stok {{ prod.stock }}</span>
                </div>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <v-col cols="12" md="4">
        <SideBarRight />
      </v-col>
    </v-row>

    <!-- Template Struk Thermal Tersembunyi -->
    <div style="display: none;">
      <div id="InvPckPrint">
        <div id="invoice-POS">
          <center>
            <h3>{{ setting.store_name }}</h3>
            <p>{{ setting.location_store }}<br/>Telp: {{ setting.contact }}</p>
          </center>
          <hr/>
          <p v-if="receiptOrder">
            No: {{ receiptOrder.invoice }}<br/>
            Waktu: {{ receiptOrder.time }}<br/>
            Platform: {{ receiptOrder.platform }} · {{ receiptOrder.method }}
          </p>
          <table v-if="receiptOrder" style="width: 100%; font-size: 11px;">
            <tr v-for="item in receiptOrder.items" :key="item.id">
              <td>{{ item.title }} x{{ item.quantity }}</td>
              <td style="text-align: right;">{{ (item.price * item.quantity).toLocaleString('id-ID') }}</td>
            </tr>
          </table>
          <hr/>
          <div v-if="receiptOrder" style="font-size: 11px; text-align: right;">
            <div>Subtotal: Rp {{ receiptOrder.subtotal.toLocaleString('id-ID') }}</div>
            <div v-if="receiptOrder.discount > 0">Diskon: -Rp {{ receiptOrder.discount.toLocaleString('id-ID') }}</div>
            <div>PPN ({{ setting.tax }}%): Rp {{ receiptOrder.tax.toLocaleString('id-ID') }}</div>
            <strong>Total: Rp {{ receiptOrder.total.toLocaleString('id-ID') }}</strong>
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
  }),
  computed: {
    ...mapGetters(['products', 'categories', 'platform', 'setting']),
    filteredProducts() {
      return this.products.filter((p) => {
        const matchCat = this.selectedCategory === 'Semua' || p.category === this.selectedCategory;
        const title = (p.title || '').toLowerCase();
        const sku = (p.sku || '').toLowerCase();
        const keyword = this.search.toLowerCase();
        const matchSearch = title.includes(keyword) || sku.includes(keyword);
        return matchCat && matchSearch;
      });
    },
  },
  async created() {
    // Selalu muat ulang data terbaru dari backend saat layar Kasir dibuka (terutama setelah browser di-refresh)
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
    getDisplayPrice(prod) {
      return (prod.platformPrices && prod.platformPrices[this.platform]) || prod.price;
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
</style>