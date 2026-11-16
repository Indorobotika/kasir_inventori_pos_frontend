<template>
  <v-card flat outlined class="rounded-xl pa-4 d-flex flex-column white" style="height: calc(100vh - 36px); position: sticky; top: 18px;">
    <div class="d-flex justify-space-between align-center mb-3">
      <div class="subtitle-1 font-weight-bold">Keranjang ({{ totalQuantity }})</div>
      <v-btn v-if="carts.length" text x-small color="red" @click="$store.commit('CLEAR_CART')">Kosongkan</v-btn>
    </div>

    <div class="flex-grow-1 overflow-y-auto pr-1">
      <div v-if="carts.length === 0" class="text-center py-12 grey--text">
        <v-icon size="48" color="grey lighten-2">mdi-shopping-outline</v-icon>
        <div class="body-2 mt-2">Keranjang belanja kosong</div>
      </div>

      <v-card
        v-for="item in carts"
        :key="item.id"
        flat
        class="pa-2 mb-2 rounded-lg grey lighten-4 d-flex align-center justify-space-between"
      >
        <div style="max-width: 145px;">
          <div class="body-2 font-weight-bold text-truncate">{{ item.title }}</div>
          <div class="caption teal--text text--darken-4 font-weight-bold">
            Rp {{ Number(item.activePrice).toLocaleString('id-ID') }}
          </div>
        </div>
        <div class="d-flex align-center">
          <v-btn icon x-small @click="$store.commit('REMOVE_CART', item)"><v-icon small>mdi-minus</v-icon></v-btn>
          <span class="mx-2 font-weight-bold body-2">{{ item.quantity }}</span>
          <v-btn icon x-small @click="$store.commit('ADD_CART', item)"><v-icon small>mdi-plus</v-icon></v-btn>
        </div>
      </v-card>
    </div>

    <div class="pt-3 border-top">
      <div class="d-flex justify-space-between caption grey--text text--darken-1 mb-1">
        <span>Subtotal</span>
        <span>Rp {{ totalPrice.toLocaleString('id-ID') }}</span>
      </div>
      <div v-if="discountAmount > 0" class="d-flex justify-space-between caption green--text text--darken-3 mb-1">
        <span>Promo ({{ activePromo.title }})</span>
        <span>-Rp {{ discountAmount.toLocaleString('id-ID') }}</span>
      </div>
      <div class="d-flex justify-space-between caption grey--text text--darken-1 mb-2">
        <span>PPN ({{ setting.tax }}%)</span>
        <span>Rp {{ taxAmount.toLocaleString('id-ID') }}</span>
      </div>
      <div class="d-flex justify-space-between subtitle-1 font-weight-bold mb-3">
        <span>Total</span>
        <span class="teal--text text--darken-4">Rp {{ grandTotal.toLocaleString('id-ID') }}</span>
      </div>

      <v-btn
        block
        large
        color="#0f4c3a"
        dark
        rounded
        depressed
        :disabled="carts.length === 0"
        @click="dialogPay = true"
      >
        <v-icon left small>mdi-shopping-outline</v-icon>
        Lihat Keranjang ({{ totalQuantity }}) — Rp {{ grandTotal.toLocaleString('id-ID') }}
      </v-btn>
    </div>

    <!-- Modal Pembayaran Hybrid -->
    <v-dialog v-model="dialogPay" max-width="440" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Pembayaran</h3>
          <v-btn icon small :disabled="isProcessing" @click="dialogPay = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-alert v-if="checkoutError" type="error" dense text class="mb-3 caption">
          {{ checkoutError }}
        </v-alert>

        <v-sheet color="#f3f6f4" class="pa-3 rounded-lg mb-4 text-center">
          <div class="caption grey--text text--darken-2">Total Tagihan · {{ platform }}</div>
          <div class="display-1 font-weight-bold teal--text text--darken-4">
            Rp {{ grandTotal.toLocaleString('id-ID') }}
          </div>
        </v-sheet>

        <div class="caption font-weight-bold mb-2">Metode Pembayaran:</div>
        <v-btn-toggle v-model="paymentMethod" mandatory color="#0f4c3a" class="d-flex mb-4">
          <v-btn value="CASH" class="flex-grow-1"><v-icon left small>mdi-cash</v-icon> Tunai</v-btn>
          <v-btn value="QRIS" class="flex-grow-1"><v-icon left small>mdi-qrcode</v-icon> QRIS</v-btn>
          <v-btn value="CARD" class="flex-grow-1"><v-icon left small>mdi-credit-card</v-icon> Kartu</v-btn>
        </v-btn-toggle>

        <div v-if="paymentMethod === 'CASH'">
          <v-text-field
            v-model.number="cashReceived"
            label="Nominal Tunai Diterima (Rp)"
            type="number"
            outlined
            dense
            class="rounded-lg"
          ></v-text-field>
          <div class="d-flex justify-space-between body-2 font-weight-bold mb-4">
            <span>Kembalian:</span>
            <span class="green--text text--darken-3">Rp {{ Math.max(0, cashReceived - grandTotal).toLocaleString('id-ID') }}</span>
          </div>
        </div>

        <div v-if="paymentMethod === 'QRIS'" class="text-center py-2">
          <div v-if="isGeneratingQris" class="py-6">
            <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
            <div class="caption grey--text mt-2">Menyiapkan kode QRIS...</div>
          </div>
          <template v-else>
            <qrcode-vue :value="qrisPayload" :size="170" level="H" class="mx-auto mb-2" />
            <div class="caption grey--text">Scan QRIS untuk menyelesaikan pembayaran</div>
          </template>
        </div>

        <v-btn
          block
          large
          color="#0f4c3a"
          dark
          rounded
          depressed
          class="mt-3"
          :loading="isProcessing"
          :disabled="paymentMethod === 'CASH' && cashReceived < grandTotal"
          @click="processCheckout"
        >
          Konfirmasi & Cetak Struk
        </v-btn>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script>
import { mapGetters } from 'vuex';
import QrcodeVue from 'qrcode.vue';
import apiClient from '@/services/api';

export default {
  name: 'SideBarRight',
  components: { QrcodeVue },
  data: () => ({
    dialogPay: false,
    paymentMethod: 'QRIS',
    cashReceived: 0,
    isProcessing: false,
    isGeneratingQris: false,
    serverQrisString: '',
    checkoutError: '',
  }),
  computed: {
    ...mapGetters(['carts', 'totalQuantity', 'totalPrice', 'setting', 'platform', 'promotions']),
    activePromo() {
      return this.promotions
        .filter((p) => p.active && this.totalPrice >= Number(p.minSpend || p.min_spend || 0))
        .sort((a, b) => Number(b.value) - Number(a.value))[0] || null;
    },
    discountAmount() {
      if (!this.activePromo) return 0;
      const val = Number(this.activePromo.value || 0);
      return this.activePromo.type === 'percent'
        ? Math.round(this.totalPrice * (val / 100))
        : val;
    },
    taxAmount() {
      return Math.round(Math.max(0, this.totalPrice - this.discountAmount) * (Number(this.setting.tax || 0) / 100));
    },
    grandTotal() {
      return Math.max(0, this.totalPrice - this.discountAmount) + this.taxAmount;
    },
    qrisPayload() {
      return this.serverQrisString || `000201010212-POS-${this.platform}-${this.grandTotal}`;
    },
  },
  watch: {
    dialogPay(v) {
      if (v) {
        this.checkoutError = '';
        this.cashReceived = this.grandTotal;
        if (this.paymentMethod === 'QRIS') {
          this.fetchQrisFromBackend();
        }
      }
    },
    paymentMethod(method) {
      if (this.dialogPay && method === 'QRIS') {
        this.fetchQrisFromBackend();
      }
    },
  },
  methods: {
    async fetchQrisFromBackend() {
      this.isGeneratingQris = true;
      this.serverQrisString = '';
      try {
        const res = await apiClient.post('/payment-qris/generate', {
          amount: this.grandTotal,
          platform: this.platform,
        });
        const data = res.data.data || res.data;
        this.serverQrisString = data.qr_string || data.qris_string || data.payload || '';
      } catch (e) {
        // Gunakan fallback qrisPayload lokal jika generator gateway belum aktif
        this.serverQrisString = '';
      } finally {
        this.isGeneratingQris = false;
      }
    },
    async processCheckout() {
      this.isProcessing = true;
      this.checkoutError = '';

      const now = new Date();
      const totalHpp = this.carts.reduce((s, i) => s + Number(i.cost_price || 0) * i.quantity, 0);
      const orderPayload = {
        invoice: 'INV-' + now.toISOString().slice(2, 10).replace(/-/g, '') + '-' + Math.floor(100000000 + Math.random() * 900000000),
        date: now.toISOString().slice(0, 10),
        time: now.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) + ', ' + now.toTimeString().slice(0, 5).replace(':', '.'),
        customer: 'Umum',
        platform: this.platform,
        method: this.paymentMethod,
        payment_method: this.paymentMethod,
        subtotal: this.totalPrice,
        discount: this.discountAmount,
        tax: this.taxAmount,
        hpp: totalHpp,
        total: this.grandTotal,
        cash_received: this.paymentMethod === 'CASH' ? this.cashReceived : this.grandTotal,
        change_amount: this.paymentMethod === 'CASH' ? Math.max(0, this.cashReceived - this.grandTotal) : 0,
        status: 'Selesai',
        items: this.carts.map((c) => ({
          id: c.id,
          product_id: c.id,
          title: c.title,
          category: c.category,
          quantity: c.quantity,
          price: c.activePrice,
          cost: Number(c.cost_price || 0),
        })),
      };

      try {
        // Kirim transaksi ke POST /api/payment-pos
        const savedOrder = await this.$store.dispatch('submitOrder', orderPayload);

        // Gabungkan data respons backend dengan struktur lokal agar cetak struk tetap utuh
        const finalOrder = {
          ...orderPayload,
          ...(typeof savedOrder === 'object' ? savedOrder : {}),
          items: orderPayload.items,
        };

        // Refresh stok produk & bahan baku terbaru dari server
        this.$store.dispatch('fetchPosData');

        this.dialogPay = false;
        this.$root.$emit('trigger-print-invoice', finalOrder);
      } catch (error) {
        this.checkoutError =
          (error.response && error.response.data && error.response.data.message) ||
          'Transaksi gagal disimpan ke server. Periksa koneksi backend Anda.';
      } finally {
        this.isProcessing = false;
      }
    },
  },
};
</script>