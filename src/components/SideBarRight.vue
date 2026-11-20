<template>
  <v-card
    flat
    outlined
    class="rounded-xl pa-4 d-flex flex-column cart-sidebar"
    :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'"
    :style="{ height: 'auto', minHeight: 'calc(100vh - 36px)', position: 'sticky', top: '18px' }"
  >
    <div class="d-flex justify-space-between align-center mb-3">
      <div class="subtitle-1 font-weight-bold tabular-num">Keranjang ({{ totalQuantity }})</div>
      <transition name="fade-fast">
        <v-btn v-if="carts.length" text x-small color="red" @click="$store.commit('CLEAR_CART')">Kosongkan</v-btn>
      </transition>
    </div>

    <!-- Banner Pengingat Jika Ada Draft QRIS Aktif -->
    <transition name="slide-fade">
      <v-alert
        v-if="pendingQrisOrder && !dialogPay"
        type="warning"
        dense
        outlined
        class="rounded-lg mb-3 caption"
      >
        <div><strong>Draft QRIS Aktif:</strong> {{ activeQrisInvoice }}</div>
        <div class="mt-1">Selesaikan pembayaran atau batalkan draft sebelum mengubah keranjang.</div>
        <v-btn
          x-small
          outlined
          color="red"
          class="mt-2 font-weight-bold"
          :loading="isCancelingDraft"
          @click="cancelPendingQrisOrder('Dibatalkan karena ingin mengubah item keranjang')"
        >
          Batalkan Draft QRIS
        </v-btn>
      </v-alert>
    </transition>

    <!-- Input Nama Pelanggan Opsional -->
    <v-text-field
      v-model="customerName"
      placeholder="Nama Pelanggan (Opsional)"
      prepend-inner-icon="mdi-account-outline"
      outlined
      dense
      hide-details
      :disabled="Boolean(pendingQrisOrder)"
      class="rounded-lg mb-3"
    ></v-text-field>

    <div class="flex-grow-1 overflow-y-auto pr-1" style="max-height: 40vh;">
      <transition name="fade-fast" mode="out-in">
        <div v-if="carts.length === 0" key="empty" class="text-center py-8 grey--text">
          <v-icon size="48" color="grey lighten-2" class="empty-icon">mdi-shopping-outline</v-icon>
          <div class="body-2 mt-2">Keranjang belanja kosong</div>
        </div>

        <transition-group v-else key="list" name="cart-list" tag="div">
          <v-card
            v-for="item in carts"
            :key="item.id"
            flat
            class="pa-2 mb-2 rounded-lg d-flex align-center justify-space-between cart-item"
            :color="$vuetify.theme.dark ? '#2a2a2a' : 'grey lighten-4'"
          >
            <div style="max-width: 145px;">
              <div class="body-2 font-weight-bold text-truncate">{{ item.title }}</div>
              <div class="caption teal--text text--lighten-2 font-weight-bold tabular-num">
                Rp {{ Number(item.activePrice || item.price).toLocaleString('id-ID') }}
              </div>
            </div>
            <div class="d-flex align-center">
              <v-btn
                icon
                x-small
                class="qty-btn"
                :disabled="Boolean(pendingQrisOrder)"
                @click="$store.commit('REMOVE_CART', item)"
              >
                <v-icon small>mdi-minus</v-icon>
              </v-btn>
              <span class="mx-2 font-weight-bold body-2 tabular-num">{{ item.quantity }}</span>
              <v-btn
                icon
                x-small
                class="qty-btn"
                :disabled="Boolean(pendingQrisOrder) || isMaxStockReached(item)"
                @click="$store.commit('ADD_CART', item)"
              >
                <v-icon small>mdi-plus</v-icon>
              </v-btn>
            </div>
          </v-card>
        </transition-group>
      </transition>
    </div>

    <div class="pt-3 border-top">
      <div class="d-flex justify-space-between caption grey--text text--darken-1 mb-1">
        <span>Subtotal</span>
        <span class="tabular-num">Rp {{ totalPrice.toLocaleString('id-ID') }}</span>
      </div>
      <transition name="slide-fade">
        <div v-if="discountAmount > 0 && activePromo" class="d-flex justify-space-between caption green--text text--darken-3 mb-1">
          <span>Promo ({{ activePromo.title }})</span>
          <span class="tabular-num">-Rp {{ discountAmount.toLocaleString('id-ID') }}</span>
        </div>
      </transition>
      <div class="d-flex justify-space-between caption grey--text text--darken-1 mb-2">
        <span>PPN ({{ Number(setting && setting.tax ? setting.tax : 0) }}%)</span>
        <span class="tabular-num">Rp {{ taxAmount.toLocaleString('id-ID') }}</span>
      </div>
      <div class="d-flex justify-space-between subtitle-1 font-weight-bold mb-3">
        <span>Total</span>
        <span class="teal--text text--lighten-2 tabular-num">Rp {{ displayGrandTotal.toLocaleString('id-ID') }}</span>
      </div>

      <v-btn
        block
        large
        color="#0f4c3a"
        dark
        rounded
        depressed
        class="pay-cta tabular-num"
        :disabled="carts.length === 0"
        @click="dialogPay = true"
      >
        <v-icon left small>mdi-shopping-outline</v-icon>
        Bayar ({{ totalQuantity }}) — Rp {{ displayGrandTotal.toLocaleString('id-ID') }}
      </v-btn>
    </div>

    <!-- Modal Pembayaran Hybrid -->
    <v-dialog v-model="dialogPay" max-width="450" persistent transition="dialog-bottom-transition">
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Pembayaran</h3>
          <v-btn
            icon
            small
            :disabled="isBusy"
            @click="closePayDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>

        <transition name="slide-fade">
          <v-alert v-if="checkoutError" type="error" dense text class="mb-3 caption rounded-lg">
            {{ checkoutError }}
          </v-alert>
        </transition>

        <!-- Info Jika Sedang Ada Draft QRIS -->
        <transition name="slide-fade">
          <v-alert
            v-if="pendingQrisOrder"
            type="info"
            dense
            outlined
            class="mb-3 caption rounded-lg"
          >
            <div class="d-flex justify-space-between align-center flex-wrap">
              <span>
                QRIS aktif untuk <strong>{{ activeQrisInvoice }}</strong> (Rp {{ Number(pendingQrisOrder.total_bill || 0).toLocaleString('id-ID') }}).
              </span>
              <v-btn
                x-small
                text
                color="red"
                class="font-weight-bold px-1"
                :loading="isCancelingDraft"
                @click="cancelAndAddMoreItems"
              >
                Tambah Barang
              </v-btn>
            </div>
          </v-alert>
        </transition>

        <v-sheet :color="$vuetify.theme.dark ? '#2a2a2a' : '#f3f6f4'" class="pa-3 rounded-lg mb-4 text-center">
          <div class="caption grey--text text--darken-2">Total Tagihan · {{ platform }}</div>
          <div class="display-1 font-weight-bold teal--text text--lighten-2 tabular-num">
            Rp {{ displayGrandTotal.toLocaleString('id-ID') }}
          </div>
        </v-sheet>

        <div class="caption font-weight-bold mb-2">Metode Pembayaran:</div>
        <v-btn-toggle
          :value="paymentMethod"
          mandatory
          color="#0f4c3a"
          class="d-flex mb-4"
          :disabled="isBusy"
          @change="onPaymentMethodChange"
        >
          <v-btn value="CASH" class="flex-grow-1"><v-icon left small>mdi-cash</v-icon> Tunai</v-btn>
          <v-btn value="QRIS" class="flex-grow-1"><v-icon left small>mdi-qrcode</v-icon> QRIS</v-btn>
          <v-btn value="CARD" class="flex-grow-1"><v-icon left small>mdi-credit-card</v-icon> Kartu</v-btn>
        </v-btn-toggle>

        <transition name="fade-fast" mode="out-in">
          <div v-if="paymentMethod === 'CASH'" key="cash">
            <v-text-field
              v-model.number="cashReceived"
              label="Nominal Tunai Diterima (Rp)"
              type="number"
              min="0"
              outlined
              dense
              class="rounded-lg"
            ></v-text-field>
            <div class="d-flex justify-space-between body-2 font-weight-bold mb-4">
              <span>Kembalian:</span>
              <span class="green--text text--darken-2 tabular-num">
                Rp {{ Math.max(0, Number(cashReceived || 0) - displayGrandTotal).toLocaleString('id-ID') }}
              </span>
            </div>
          </div>

          <div v-else-if="paymentMethod === 'CARD'" key="card">
            <v-text-field
              v-model="numberCard"
              label="Nomor Kartu / Referensi EDC (Opsional)"
              outlined
              dense
              class="rounded-lg"
            ></v-text-field>
          </div>

          <div v-else-if="paymentMethod === 'QRIS'" key="qris" class="text-center py-2">
            <div v-if="isGeneratingQris" class="py-6">
              <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
              <div class="caption grey--text mt-2">Menyiapkan QRIS toko...</div>
            </div>
            <template v-else-if="serverQrisString || (setting && setting.qris_path_url)">
              <v-img
                v-if="setting && setting.qris_path_url"
                :src="setting.qris_path_url"
                max-width="180"
                max-height="180"
                class="mx-auto mb-2 rounded-lg elevation-1 white pa-2 qris-preview"
                contain
              ></v-img>
              <qrcode-vue
                v-else-if="serverQrisString"
                :value="serverQrisString"
                :size="170"
                level="H"
                class="mx-auto mb-2 qris-preview"
              />

              <div v-if="activeQrisInvoice" class="caption font-weight-bold mt-1">{{ activeQrisInvoice }}</div>
              <div class="caption teal--text font-weight-bold tabular-num">Total: Rp {{ displayGrandTotal.toLocaleString('id-ID') }}</div>
              <div class="caption grey--text mb-2">Scan QRIS di atas, lalu klik tombol di bawah setelah pembayaran berhasil</div>
            </template>
            <div v-else class="caption grey--text py-3">
              Gambar QRIS belum diatur di menu Pengaturan. Silakan unggah terlebih dahulu.
            </div>
          </div>
        </transition>

        <v-btn
          block
          large
          color="#0f4c3a"
          dark
          rounded
          depressed
          class="mt-3 pay-cta"
          :loading="isBusy"
          :disabled="paymentMethod === 'CASH' && Number(cashReceived || 0) < displayGrandTotal"
          @click="handleMainAction"
        >
          {{ mainButtonLabel }}
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
    isCancelingDraft: false,
    serverQrisString: '',
    activeQrisInvoice: '',
    pendingQrisOrder: null,
    pendingQrisOrderId: null,
    checkoutError: '',
  }),
  computed: {
    ...mapGetters(['carts', 'totalQuantity', 'totalPrice', 'setting', 'platform', 'promotions']),
    isBusy() {
      return this.isProcessing || this.isGeneratingQris || this.isCancelingDraft;
    },
    activePromo() {
      const promos = Array.isArray(this.promotions) ? this.promotions : [];
      return (
        promos
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
      const taxRate = Number(this.setting && this.setting.tax ? this.setting.tax : 0);
      return Math.round(Math.max(0, this.totalPrice - this.discountAmount) * (taxRate / 100));
    },
    grandTotal() {
      return Math.max(0, this.totalPrice - this.discountAmount) + this.taxAmount;
    },
    displayGrandTotal() {
      if (this.pendingQrisOrder && this.paymentMethod === 'QRIS') {
        return Number(this.pendingQrisOrder.total_bill || this.grandTotal);
      }
      return this.grandTotal;
    },
    mainButtonLabel() {
      const hasQrisVisual = Boolean(this.serverQrisString || (this.setting && this.setting.qris_path_url));
      if (this.paymentMethod === 'QRIS' && !hasQrisVisual) {
        return 'Buat Kode QRIS';
      }
      return 'Konfirmasi Lunas & Cetak Struk';
    },
  },
  watch: {
    dialogPay(v) {
      if (v) {
        this.checkoutError = '';
        this.cashReceived = this.displayGrandTotal;
      }
    },
  },
  methods: {
    isMaxStockReached(item) {
      const isRecipe = (item.product_type || item.type || '').toLowerCase() === 'resep';
      if (isRecipe || item.stock === null || item.stock === undefined) return false;
      return Number(item.quantity || 0) + 1 > Number(item.stock);
    },
    resetDraftState() {
      this.serverQrisString = '';
      this.activeQrisInvoice = '';
      this.pendingQrisOrder = null;
      this.pendingQrisOrderId = null;
    },
    closePayDialog() {
      if (this.isBusy) return;
      this.dialogPay = false;
      this.checkoutError = '';
    },
    async cancelPendingQrisOrder(reason = 'Dibatalkan kasir') {
      if (!this.pendingQrisOrderId) {
        this.resetDraftState();
        return true;
      }

      this.isCancelingDraft = true;
      this.checkoutError = '';
      try {
        await apiClient.post(`/orders/${this.pendingQrisOrderId}/cancel`, {
          berita_acara: reason,
        });
        this.resetDraftState();
        await this.$store.dispatch('fetchPosData');
        return true;
      } catch (error) {
        this.checkoutError =
          (error && error.response && error.response.data && error.response.data.message) ||
          'Gagal membatalkan draft pesanan QRIS sebelumnya.';
        return false;
      } finally {
        this.isCancelingDraft = false;
      }
    },
    async cancelAndAddMoreItems() {
      const ok = await this.cancelPendingQrisOrder('Dibatalkan untuk menambah atau mengubah item pesanan');
      if (ok) {
        this.dialogPay = false;
      }
    },
    async onPaymentMethodChange(nextMethod) {
      if (!nextMethod || nextMethod === this.paymentMethod) return;
      this.checkoutError = '';

      // Jika QRIS sudah ter-generate dan order pending sudah dibuat, batalkan draft lama sebelum ganti metode
      if (this.paymentMethod === 'QRIS' && this.pendingQrisOrderId) {
        const canceled = await this.cancelPendingQrisOrder(`Ganti metode pembayaran dari QRIS ke ${nextMethod}`);
        if (!canceled) return;
      }

      this.paymentMethod = nextMethod;
      if (nextMethod === 'CASH') {
        this.cashReceived = this.grandTotal;
      }
      if (nextMethod !== 'CARD') {
        this.numberCard = '';
      }
    },
    async handleMainAction() {
      const hasQrisVisual = Boolean(this.serverQrisString || (this.setting && this.setting.qris_path_url));
      if (this.paymentMethod === 'QRIS' && !hasQrisVisual) {
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
        carts: this.carts.map((c) => {
          const isRm =
            c.source_type === 'raw_material' ||
            Boolean(c.raw_material_id) ||
            String(c.id || '').indexOf('rm_') === 0;

          return {
            id: c.id,
            quantity: c.quantity,
            source_type: isRm ? 'raw_material' : 'product',
            raw_material_id: isRm
              ? (c.raw_material_id || Number(String(c.id).replace(/^rm_/, '')))
              : null,
          };
        }),
        payment_method: this.paymentMethod,
        platform: this.platform,
        customer_name: this.customerName.trim() || 'Umum',
        numberCard: this.paymentMethod === 'CARD' ? this.numberCard : null,
        nominalCash: this.paymentMethod === 'CASH' ? Number(this.cashReceived || 0) : this.grandTotal,
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
        const orderData = (res && res.data && res.data.data) ? res.data.data : (res ? res.data : {});

        const qrisRes = await apiClient.post('/payment-qris/generate', {
          order_id: orderData.order_id,
        });
        const qrisData = (qrisRes && qrisRes.data) ? qrisRes.data : {};

        this.serverQrisString = qrisData.qris_string || '';
        this.activeQrisInvoice = orderData.invoice_number || '';
        this.pendingQrisOrderId = orderData.order_id || null;
        this.pendingQrisOrder = this.buildReceiptSnapshot(orderData);
      } catch (error) {
        this.checkoutError =
          (error && error.response && error.response.data && error.response.data.message) ||
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
          (error && error.response && error.response.data && error.response.data.message) ||
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
        const orderData = (res && res.data && res.data.data) ? res.data.data : (res ? res.data : {});
        const snapshot = this.buildReceiptSnapshot(orderData);

        this.finalizeReceipt(snapshot);
      } catch (error) {
        this.checkoutError =
          (error && error.response && error.response.data && error.response.data.message) ||
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
      this.resetDraftState();
      this.$root.$emit('trigger-print-invoice', receiptSnapshot);
    },
  },
};
</script>

<style scoped>
.tabular-num {
  font-variant-numeric: tabular-nums;
}

.cart-sidebar {
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.cart-item {
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.2s ease;
}

.cart-item:hover {
  transform: translateX(2px);
}

.qty-btn {
  transition: transform 0.14s cubic-bezier(0.22, 1, 0.36, 1);
}

.qty-btn:active:not(:disabled) {
  transform: scale(0.86);
}

.pay-cta {
  transition: transform 0.18s cubic-bezier(0.22, 1, 0.36, 1), box-shadow 0.2s ease;
}

.pay-cta:not(:disabled):hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(15, 76, 58, 0.22);
}

.pay-cta:not(:disabled):active {
  transform: scale(0.98);
}

.qris-preview {
  animation: qrisPop 0.32s cubic-bezier(0.22, 1, 0.36, 1) both;
}

@keyframes qrisPop {
  from {
    opacity: 0;
    transform: scale(0.92);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.cart-list-enter-active,
.cart-list-leave-active {
  transition: all 0.24s cubic-bezier(0.22, 1, 0.36, 1);
}

.cart-list-enter {
  opacity: 0;
  transform: translateY(-8px) scale(0.97);
}

.cart-list-leave-to {
  opacity: 0;
  transform: translateX(14px) scale(0.96);
}

.cart-list-move {
  transition: transform 0.24s cubic-bezier(0.22, 1, 0.36, 1);
}

.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.22s ease;
}

.slide-fade-enter,
.slide-fade-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}

.fade-fast-enter-active,
.fade-fast-leave-active {
  transition: opacity 0.2s ease;
}

.fade-fast-enter,
.fade-fast-leave-to {
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .qris-preview {
    animation: none !important;
  }
  .cart-sidebar,
  .cart-item,
  .qty-btn,
  .pay-cta,
  .cart-list-enter-active,
  .cart-list-leave-active,
  .cart-list-move,
  .slide-fade-enter-active,
  .slide-fade-leave-active,
  .fade-fast-enter-active,
  .fade-fast-leave-active {
    transition: none !important;
  }
}
</style>