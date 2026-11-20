<template>
  <v-container fluid class="pa-3 pa-md-5">
    <!-- Header -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Pesanan</h1>
        <div class="caption grey--text text--darken-1">Riwayat transaksi dan laporan penjualan harian.</div>
      </div>
      <v-btn icon outlined class="rounded-lg" :loading="isLoading" @click="loadOrders">
        <v-icon small>mdi-refresh</v-icon>
      </v-btn>
    </div>

    <v-alert v-if="errorMessage && !cancelDialog" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-alert v-if="successMessage" type="success" dense outlined class="rounded-lg mb-4">
      {{ successMessage }}
    </v-alert>

    <!-- Filter Tanggal & Status (Responsif untuk HP) -->
    <div class="d-flex flex-wrap align-center mb-4">
      <v-text-field
        v-model="startDate"
        type="date"
        outlined
        dense
        hide-details
        class="rounded-lg mr-2 mb-2 flex-grow-1"
        style="max-width: 160px; min-width: 140px;"
        @change="loadOrders"
      ></v-text-field>
      <span class="mx-1 grey--text mb-2 d-none d-sm-inline">s/d</span>
      <v-text-field
        v-model="endDate"
        type="date"
        outlined
        dense
        hide-details
        class="rounded-lg mr-2 mb-2 flex-grow-1"
        style="max-width: 160px; min-width: 140px;"
        @change="loadOrders"
      ></v-text-field>
      <v-select
        v-model="statusFilter"
        :items="['Semua status', 'Selesai', 'Belum Lunas', 'Dibatalkan']"
        outlined
        dense
        hide-details
        class="rounded-lg mb-2 flex-grow-1"
        style="max-width: 180px; min-width: 150px;"
        @change="loadOrders"
      ></v-select>
    </div>

    <!-- Kartu Statistik -->
    <v-row class="mb-4">
      <v-col cols="12" sm="6" class="mb-3 mb-sm-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">TRANSAKSI SUKSES</div>
          <div class="headline font-weight-bold mt-1">{{ summary.total_transactions || 0 }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" sm="6">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">OMZET</div>
          <div class="headline font-weight-bold teal--text text--lighten-2 mt-1">
            Rp {{ Number(summary.omzet || 0).toLocaleString('id-ID') }}
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabel Daftar Pesanan dengan Wrapper Scroll Horizontal untuk Mobile -->
    <v-card flat outlined class="rounded-xl overflow-hidden" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat riwayat pesanan...</div>
      </div>

      <div v-else style="overflow-x: auto;">
        <v-simple-table style="min-width: 760px;">
          <thead>
            <tr>
              <th>Invoice</th>
              <th>Waktu</th>
              <th>Pelanggan</th>
              <th>Platform</th>
              <th>Bayar</th>
              <th>Total</th>
              <th>Status</th>
              <th class="text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="orders.length === 0">
              <td colspan="8" class="text-center py-8 grey--text">Tidak ada transaksi pada rentang tanggal ini.</td>
            </tr>
            <tr v-for="ord in orders" :key="ord.id">
              <td class="font-weight-bold">{{ ord.invoice_number }}</td>
              <td>{{ formatOrderTime(ord) }}</td>
              <td>{{ ord.customer_name || 'Umum' }}</td>
              <td>{{ ord.platform || 'Offline Store' }}</td>
              <td>{{ ord.payment_method || '-' }}</td>
              <td class="font-weight-bold">Rp {{ Number(ord.total_bill || 0).toLocaleString('id-ID') }}</td>
              <td>
                <v-chip
                  x-small
                  :color="getStatusColor(ord.status).bg"
                  :class="getStatusColor(ord.status).text"
                  class="font-weight-bold"
                >
                  {{ formatStatusLabel(ord.status) }}
                </v-chip>
              </td>
              <td class="text-right text-no-wrap">
                <!-- Tombol Pelunasan Manual (Hanya muncul jika status pending / Belum Lunas) -->
                <v-btn
                  v-if="ord.status === 'pending'"
                  text
                  x-small
                  color="orange darken-2"
                  class="font-weight-bold mr-1"
                  :loading="payingId === ord.id"
                  @click="markAsPaid(ord)"
                >
                  Lunasin
                </v-btn>

                <v-btn
                  v-if="ord.status !== 'canceled'"
                  text
                  x-small
                  color="red darken-1"
                  class="font-weight-bold mr-1"
                  :loading="cancelingId === ord.id"
                  @click="openCancelDialog(ord)"
                >
                  Batalkan
                </v-btn>

                <v-btn text x-small color="#0f4c3a" class="font-weight-bold" @click="reprint(ord)">Struk</v-btn>
              </td>
            </tr>
          </tbody>
        </v-simple-table>
      </div>
    </v-card>

    <!-- Dialog Pembatalan & Berita Acara -->
    <v-dialog v-model="cancelDialog" max-width="460" persistent>
      <v-card class="rounded-xl pa-2" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <v-card-title class="subtitle-1 font-weight-bold red--text">
          Berita Acara Pembatalan Pesanan
        </v-card-title>
        <v-card-text v-if="selectedCancelOrder">
          <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-3">
            {{ errorMessage }}
          </v-alert>

          <div class="mb-3 pa-3 rounded-lg" :style="{ backgroundColor: $vuetify.theme.dark ? '#2a2a2a' : '#f7f7f7' }">
            <div class="caption grey--text">No. Invoice</div>
            <div class="body-2 font-weight-bold mb-2">{{ selectedCancelOrder.invoice_number }}</div>
            <div class="caption grey--text">Nominal Transaksi</div>
            <div class="subtitle-2 font-weight-bold red--text">
              Rp {{ Number(selectedCancelOrder.total_bill || 0).toLocaleString('id-ID') }}
            </div>
          </div>

          <div class="caption grey--text mb-2">
            Pesanan akan ditandai dibatalkan, stok produk/bahan baku dikembalikan, dan cashflow disesuaikan berdasarkan nomor invoice.
          </div>

          <v-textarea
            v-model="beritaAcara"
            label="Berita Acara / Alasan Pembatalan"
            placeholder="Contoh: Pelanggan membatalkan pesanan karena salah input menu..."
            outlined
            dense
            rows="3"
            hide-details="auto"
          ></v-textarea>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer></v-spacer>
          <v-btn text :disabled="isSubmittingCancel" @click="closeCancelDialog">Batal</v-btn>
          <v-btn
            color="red darken-1"
            dark
            depressed
            class="rounded-lg font-weight-bold"
            :loading="isSubmittingCancel"
            @click="confirmCancelOrder"
          >
            Proses Pembatalan
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Template Struk Thermal Tersembunyi -->
    <div style="display: none;">
      <div id="OrderReceiptPrint">
        <div id="invoice-POS-order">
          <center>
            <h3>{{ setting && setting.store_name ? setting.store_name : 'Toko' }}</h3>
            <p>{{ setting && setting.location_store ? setting.location_store : '' }}<br/>Telp: {{ setting && setting.contact ? setting.contact : '-' }}</p>
          </center>
          <hr/>
          <p v-if="receiptOrder">
            No: {{ receiptOrder.invoice_number }}<br/>
            Waktu: {{ formatOrderTime(receiptOrder) }}<br/>
            Platform: {{ receiptOrder.platform || 'Offline Store' }} · {{ receiptOrder.payment_method }}
          </p>
          <table v-if="receiptOrder && receiptOrder.details" style="width: 100%; font-size: 11px;">
            <tr v-for="(item, idx) in receiptOrder.details" :key="item.id || idx">
              <td>{{ getDetailItemName(item) }} x{{ item.quantity }}</td>
              <td style="text-align: right;">{{ Number(item.subtotal || 0).toLocaleString('id-ID') }}</td>
            </tr>
          </table>
          <hr/>
          <div v-if="receiptOrder" style="font-size: 11px; text-align: right;">
            <div>Subtotal: Rp {{ Number(receiptOrder.subtotal || 0).toLocaleString('id-ID') }}</div>
            <div v-if="Number(receiptOrder.discount_amount || 0) > 0">Diskon: -Rp {{ Number(receiptOrder.discount_amount).toLocaleString('id-ID') }}</div>
            <div>PPN: Rp {{ Number(receiptOrder.tax || 0).toLocaleString('id-ID') }}</div>
            <strong>Total: Rp {{ Number(receiptOrder.total_bill || 0).toLocaleString('id-ID') }}</strong>
          </div>
          <center><p style="margin-top: 8px;">{{ setting && setting.receipt_footer ? setting.receipt_footer : 'Terima kasih' }}</p></center>
        </div>
      </div>
    </div>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

function formatLocalDate(dateObj) {
  const year = dateObj.getFullYear();
  const month = String(dateObj.getMonth() + 1).padStart(2, '0');
  const day = String(dateObj.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export default {
  name: 'OrdersView',
  data() {
    const now = new Date();
    const firstDay = formatLocalDate(new Date(now.getFullYear(), now.getMonth(), 1));
    const lastDay = formatLocalDate(new Date(now.getFullYear(), now.getMonth() + 1, 0));
    return {
      startDate: firstDay,
      endDate: lastDay,
      statusFilter: 'Semua status',
      isLoading: false,
      payingId: null,
      cancelingId: null,
      cancelDialog: false,
      selectedCancelOrder: null,
      beritaAcara: '',
      isSubmittingCancel: false,
      errorMessage: '',
      successMessage: '',
      receiptOrder: null,
    };
  },
  computed: {
    ...mapGetters(['orders', 'summary', 'setting']),
  },
  async created() {
    await Promise.all([
      this.ensureSettingsLoaded(),
      this.loadOrders(),
    ]);
  },
  methods: {
    async ensureSettingsLoaded() {
      if (this.setting && this.setting.store_name) return;
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        // Diabaikan jika gagal memuat setting sekunder; loadOrders akan menangani auth/error utama
      }
    },
    getDetailItemName(item) {
      if (!item) return 'Produk';
      if (item.item_name) return item.item_name;
      if (item.product && item.product.title) return item.product.title;
      if (item.raw_material && item.raw_material.name) return item.raw_material.name;
      if (item.rawMaterial && item.rawMaterial.name) return item.rawMaterial.name;
      return 'Produk';
    },
    async loadOrders() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchOrders', {
          start_date: this.startDate,
          end_date: this.endDate,
          status: this.statusFilter
        });
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat riwayat pesanan dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    async markAsPaid(order) {
      this.payingId = order.id;
      this.errorMessage = '';
      this.successMessage = '';
      try {
        await apiClient.post(`/orders/${order.id}/pay`);
        this.successMessage = `Pesanan ${order.invoice_number} berhasil dilunasi.`;
        await this.loadOrders();
      } catch (err) {
        this.errorMessage = (err && err.response && err.response.data && err.response.data.message) || 'Gagal mengubah status pelunasan.';
      } finally {
        this.payingId = null;
      }
    },
    openCancelDialog(order) {
      this.selectedCancelOrder = order;
      this.beritaAcara = '';
      this.errorMessage = '';
      this.cancelDialog = true;
    },
    closeCancelDialog() {
      if (this.isSubmittingCancel) return;
      this.errorMessage = '';
      this.cancelDialog = false;
      this.selectedCancelOrder = null;
      this.beritaAcara = '';
    },
    async confirmCancelOrder() {
      if (!this.selectedCancelOrder) return;
      if (!this.beritaAcara || this.beritaAcara.trim().length < 3) {
        this.errorMessage = 'Silakan isi berita acara pembatalan minimal 3 karakter.';
        return;
      }

      this.isSubmittingCancel = true;
      this.cancelingId = this.selectedCancelOrder.id;
      this.errorMessage = '';
      this.successMessage = '';

      try {
        const res = await apiClient.post(`/orders/${this.selectedCancelOrder.id}/cancel`, {
          berita_acara: this.beritaAcara.trim(),
        });
        this.cancelDialog = false;
        this.selectedCancelOrder = null;
        this.beritaAcara = '';
        this.successMessage = (res && res.data && res.data.message) || 'Pesanan berhasil dibatalkan.';
        await this.loadOrders();
      } catch (err) {
        this.errorMessage = (err && err.response && err.response.data && err.response.data.message) || 'Gagal membatalkan pesanan.';
      } finally {
        this.isSubmittingCancel = false;
        this.cancelingId = null;
      }
    },
    formatOrderTime(ord) {
      if (ord && ord.created_at) return String(ord.created_at).replace('T', ' ').slice(0, 16);
      return '-';
    },
    formatStatusLabel(status) {
      if (status === 'canceled') return 'Dibatalkan';
      if (status === 'pending') return 'Belum Lunas';
      return 'Selesai';
    },
    getStatusColor(status) {
      const isDark = this.$vuetify.theme.dark;
      if (status === 'canceled') {
        return {
          bg: isDark ? 'red darken-4' : 'red lighten-4',
          text: isDark ? 'red--text text--lighten-3' : 'red--text text--darken-3'
        };
      }
      if (status === 'pending') {
        return {
          bg: isDark ? 'amber darken-4' : 'amber lighten-4',
          text: isDark ? 'amber--text text--lighten-3' : 'amber--text text--darken-4'
        };
      }
      return {
        bg: isDark ? 'green darken-4' : 'green lighten-4',
        text: isDark ? 'green--text text--lighten-3' : 'green--text text--darken-3'
      };
    },
    reprint(order) {
      this.receiptOrder = order;
      this.errorMessage = '';
      this.$nextTick(() => {
        const divToPrint = document.getElementById('OrderReceiptPrint');
        if (!divToPrint) return;
        const width = this.setting && this.setting.receipt_width === '80 mm' ? '80mm' : '58mm';
        const win = window.open('', '_blank', 'width=340,height=600');
        if (!win) {
          this.errorMessage = 'Popup cetak struk diblokir browser. Izinkan popup untuk mencetak struk.';
          return;
        }
        win.document.write(`
          <html><head><title>Struk ${order.invoice_number || ''}</title>
          <style>
            #invoice-POS-order { width: ${width}; margin: 0 auto; font-family: monospace; font-size: 11px; }
          </style>
          </head><body>${divToPrint.innerHTML}</body></html>
        `);
        win.document.close();
        win.focus();
        setTimeout(() => { win.print(); win.close(); }, 250);
      });
    },
  },
};
</script>