<template>
  <v-card
    flat
    outlined
    class="rounded-xl pa-4 d-flex flex-column"
    :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'"
    :style="{ height: 'auto', minHeight: 'calc(100vh - 36px)', position: 'sticky', top: '18px' }"
  >
    <div class="d-flex justify-space-between align-center mb-3">
      <div class="subtitle-1 font-weight-bold">Keranjang ({{ totalQuantity }})</div>
      <v-btn v-if="carts.length" text x-small color="red" @click="$store.commit('CLEAR_CART')">Kosongkan</v-btn>
    </div>

    <!-- Input Nama Pelanggan Opsional -->
    <v-text-field
      v-model="customerName"
      placeholder="Nama Pelanggan (Opsional)"
      prepend-inner-icon="mdi-account-outline"
      outlined
      dense
      hide-details
      class="rounded-lg mb-3"
    ></v-text-field>

    <div class="flex-grow-1 overflow-y-auto pr-1" style="max-height: 40vh;">
      <div v-if="carts.length === 0" class="text-center py-8 grey--text">
        <v-icon size="48" color="grey lighten-2">mdi-shopping-outline</v-icon>
        <div class="body-2 mt-2">Keranjang belanja kosong</div>
      </div>

      <v-card
        v-for="item in carts"
        :key="item.id"
        flat
        class="pa-2 mb-2 rounded-lg d-flex align-center justify-space-between"
        :color="$vuetify.theme.dark ? '#2a2a2a' : 'grey lighten-4'"
      >
        <div style="max-width: 145px;">
          <div class="body-2 font-weight-bold text-truncate">{{ item.title }}</div>
          <div class="caption teal--text text--lighten-2 font-weight-bold">
            Rp {{ Number(item.activePrice || item.price).toLocaleString('id-ID') }}
          </div>
        </div>
        <div class="d-flex align-center">
          <v-btn icon x-small @click="$store.commit('REMOVE_CART', item)"><v-icon small>mdi-minus</v-icon></v-btn>
          <span class="mx-2 font-weight-bold body-2">{{ item.quantity }}</span>
          <v-btn
            icon
            x-small
            :disabled="isMaxStockReached(item)"
            @click="$store.commit('ADD_CART', item)"
          >
            <v-icon small>mdi-plus</v-icon>
          </v-btn>
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
        <span>PPN ({{ Number(setting.tax || 0) }}%)</span>
        <span>Rp {{ taxAmount.toLocaleString('id-ID') }}</span>
      </div>
      <div class="d-flex justify-space-between subtitle-1 font-weight-bold mb-3">
        <span>Total</span>
        <span class="teal--text text--lighten-2">Rp {{ grandTotal.toLocaleString('id-ID') }}</span>
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
        Bayar ({{ totalQuantity }}) — Rp {{ grandTotal.toLocaleString('id-ID') }}
      </v-btn>
    </div>

    <!-- Modal Pembayaran Hybrid -->
    <v-dialog v-model="dialogPay" max-width="440" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Pembayaran</h3>
          <v-btn
            icon
            small
            :disabled="isProcessing || isGeneratingQris"
            @click="closePayDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>

        <v-alert v-if="checkoutError" type="error" dense text class="mb-3 caption">
          {{ checkoutError }}
        </v-alert>

        <v-sheet :color="$vuetify.theme.dark ? '#2a2a2a' : '#f3f6f4'" class="pa-3 rounded-lg mb-4 text-center">
          <div class="caption grey--text text--darken-2">Total Tagihan · {{ platform }}</div>
          <div class="display-1 font-weight-bold teal--text text--lighten-2">
            Rp {{ grandTotal.toLocaleString('id-ID') }}
          </div>
        </v-sheet>

        <div class="caption font-weight-bold mb-2">Metode Pembayaran:</div>
        <v-btn-toggle
          v-model="paymentMethod"
          mandatory
          color="#0f4c3a"
          class="d-flex mb-4"
          :disabled="Boolean(pendingQrisOrder)"
        >
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
            <span class="green--text text--darken-2">Rp {{ Math.max(0, cashReceived - grandTotal).toLocaleString('id-ID') }}</span>
          </div>
        </div>

        <div v-if="paymentMethod === 'CARD'">
          <v-text-field
            v-model="numberCard"
            label="Nomor Kartu / Referensi EDC (Opsional)"
            outlined
            dense
            class="rounded-lg"
          ></v-text-field>
        </div>

        <div v-if="paymentMethod === 'QRIS'" class="text-center py-2">
          <div v-if="isGeneratingQris" class="py-6">
            <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
            <div class="caption grey--text mt-2">Menyiapkan QRIS toko...</div>
          </div>
          <template v-else-if="serverQrisString || setting.qris_path_url">
            <!-- Tampilkan Gambar QRIS dari Tabel Setting -->
            <v-img
              v-if="setting.qris_path_url"
              :src="setting.qris_path_url"
              max-width="180"
              max-height="180"
              class="mx-auto mb-2 rounded-lg elevation-1 white pa-2"
              contain
            ></v-img>
            <qrcode-vue v-else-if="serverQrisString" :value="serverQrisString" :size="170" level="H" class="mx-auto mb-2" />
            
            <div class="caption font-weight-bold mt-1">{{ activeQrisInvoice }}</div>
            <div class="caption teal--text font-weight-bold">Total: Rp {{ grandTotal.toLocaleString('id-ID') }}</div>
            <div class="caption grey--text mb-2">Scan QRIS di atas, lalu klik tombol di bawah setelah pembayaran berhasil</div>
          </template>
          <div v-else class="caption grey--text py-3">
            Gambar QRIS belum diatur di menu Pengaturan. Silakan unggah terlebih dahulu.
          </div>
        </div>

        <v-btn
          block
          large
          color="#0f4c3a"
          dark
          rounded
          depressed
          class="mt-3"
          :loading="isProcessing || isGeneratingQris"
          :disabled="paymentMethod === 'CASH' && cashReceived < grandTotal"
          @click="handleMainAction"
        >
          {{ paymentMethod === 'QRIS' && !serverQrisString ? 'Buat Kode QRIS' : 'Konfirmasi Lunas & Cetak Struk' }}
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
    customerName: '',
    dialogPay: false,
    paymentMethod: 'CASH',
    cashReceived: 0,
    numberCard: '',
    isProcessing: false,
    isGeneratingQris: false,
    serverQrisString: '',
    activeQrisInvoice: '',
    pendingQrisOrder: null,
    pendingQrisOrderId: null,
    checkoutError: '',
  }),
  computed: {
    ...mapGetters(['carts', 'totalQuantity', 'totalPrice', 'setting', 'platform', 'promotions']),
    activePromo() {
      return (
        this.promotions
          .filter((p) => Number(p.is_active) === 1 && this.totalPrice >= Number(p.required || 0))
          .sort((a, b) => Number(b.result || 0) - Number(a.result || 0))[0] || null
      );
    },
    discountAmount() {
      if (!this.activePromo) return 0;
      const val = Number(this.activePromo.result || 0);
      return Number(this.activePromo.typ_promotion_id) === 2
        ? Math.round(this.totalPrice * (val / 100))
        : val;
    },
    taxAmount() {
      const taxRate = Number(this.setting.tax || 0);
      return Math.round(Math.max(0, this.totalPrice - this.discountAmount) * (taxRate / 100));
    },
    grandTotal() {
      return Math.max(0, this.totalPrice - this.discountAmount) + this.taxAmount;
    },
  },
  watch: {
    dialogPay(v) {
      if (v) {
        this.checkoutError = '';
        this.cashReceived = this.grandTotal;
        this.numberCard = '';
        this.serverQrisString = '';
        this.activeQrisInvoice = '';
        this.pendingQrisOrder = null;
        this.pendingQrisOrderId = null;
      }
    },
    paymentMethod() {
      if (!this.pendingQrisOrder) {
        this.checkoutError = '';
        this.serverQrisString = '';
      }
    },
  },
  methods: {
    isMaxStockReached(item) {
      const isRecipe = (item.product_type || item.type || '').toLowerCase() === 'resep';
      if (isRecipe || item.stock === null || item.stock === undefined) return false;
      return item.quantity >= Number(item.stock);
    },
    closePayDialog() {
      this.dialogPay = false;
      this.serverQrisString = '';
      this.pendingQrisOrder = null;
      this.pendingQrisOrderId = null;
    },
    async handleMainAction() {
      if (this.paymentMethod === 'QRIS' && !this.serverQrisString) {
        await this.createOrderAndGenerateQris();
        return;
      }

      if (this.paymentMethod === 'QRIS' && this.pendingQrisOrder) {
        await this.confirmQrisPaid();
        return;
      }

      await this.processCheckout();
    },
    buildBackendPayload() {
      return {
        carts: this.carts.map((c) => ({
          id: c.id,
          quantity: c.quantity,
        })),
        payment_method: this.paymentMethod,
        platform: this.platform,
        customer_name: this.customerName.trim() || 'Umum',
        numberCard: this.paymentMethod === 'CARD' ? this.numberCard : null,
        nominalCash: this.paymentMethod === 'CASH' ? Number(this.cashReceived) : this.grandTotal,
      };
    },
    buildReceiptSnapshot(backendData = {}) {
      const now = new Date();
      return {
        invoice_number: backendData.invoice_number || 'INV-' + Date.now(),
        time:
          now.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) +
          ', ' +
          now.toTimeString().slice(0, 5).replace(':', '.'),
        customer_name: this.customerName.trim() || 'Umum',
        platform: this.platform,
        payment_method: this.paymentMethod,
        subtotal: this.totalPrice,
        discount_amount: this.discountAmount,
        tax: this.taxAmount,
        total_bill: backendData.total_bill || this.grandTotal,
        items: this.carts.map((c) => ({
          id: c.id,
          title: c.title,
          quantity: c.quantity,
          price: Number(c.activePrice || c.price),
        })),
      };
    },
    async createOrderAndGenerateQris() {
      this.isGeneratingQris = true;
      this.checkoutError = '';
      try {
        const res = await apiClient.post('/payment-pos', this.buildBackendPayload());
        const orderData = res.data.data || res.data;

        const qrisRes = await apiClient.post('/payment-qris/generate', {
          order_id: orderData.order_id,
        });
        const qrisData = qrisRes.data;

        this.serverQrisString = qrisData.qris_string || '';
        this.activeQrisInvoice = orderData.invoice_number;
        this.pendingQrisOrderId = orderData.order_id;
        this.pendingQrisOrder = this.buildReceiptSnapshot(orderData);
      } catch (error) {
        this.checkoutError =
          (error.response && error.response.data && error.response.data.message) ||
          'Gagal membuat kode QRIS dari server.';
      } finally {
        this.isGeneratingQris = false;
      }
    },
    async confirmQrisPaid() {
      this.isProcessing = true;
      this.checkoutError = '';
      try {
        if (this.pendingQrisOrderId) {
          await apiClient.post(`/orders/${this.pendingQrisOrderId}/pay`);
        }
        const snapshot = this.pendingQrisOrder;
        this.finalizeReceipt(snapshot);
      } catch (error) {
        this.checkoutError =
          (error.response && error.response.data && error.response.data.message) ||
          'Gagal mengonfirmasi pelunasan QRIS.';
      } finally {
        this.isProcessing = false;
      }
    },
    async processCheckout() {
      this.isProcessing = true;
      this.checkoutError = '';
      try {
        const res = await apiClient.post('/payment-pos', this.buildBackendPayload());
        const orderData = res.data.data || res.data;
        const snapshot = this.buildReceiptSnapshot(orderData);

        this.finalizeReceipt(snapshot);
      } catch (error) {
        this.checkoutError =
          (error.response && error.response.data && error.response.data.message) ||
          'Transaksi gagal disimpan ke server. Periksa stok produk/bahan baku.';
      } finally {
        this.isProcessing = false;
      }
    },
    finalizeReceipt(receiptSnapshot) {
      this.$store.commit('CLEAR_CART');
      this.$store.dispatch('fetchPosData');
      this.customerName = '';
      this.dialogPay = false;
      this.serverQrisString = '';
      this.pendingQrisOrder = null;
      this.pendingQrisOrderId = null;
      this.$root.$emit('trigger-print-invoice', receiptSnapshot);
    },
  },
};
</script>