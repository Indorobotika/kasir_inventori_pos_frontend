<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Pesanan</h1>
        <div class="caption grey--text text--darken-1">Riwayat transaksi dan laporan penjualan harian.</div>
      </div>
      <v-btn icon outlined class="rounded-lg white" :loading="isLoading" @click="loadOrders">
        <v-icon small>mdi-refresh</v-icon>
      </v-btn>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <div class="d-flex flex-wrap align-center mb-4">
      <v-text-field
        v-model="startDate"
        type="date"
        outlined
        dense
        hide-details
        class="rounded-lg white mr-2 mb-2"
        style="max-width: 170px;"
      ></v-text-field>
      <span class="mx-2 grey--text mb-2">s/d</span>
      <v-text-field
        v-model="endDate"
        type="date"
        outlined
        dense
        hide-details
        class="rounded-lg white mr-3 mb-2"
        style="max-width: 170px;"
      ></v-text-field>
      <v-select
        v-model="statusFilter"
        :items="['Semua status', 'Selesai', 'Belum Lunas', 'Dibatalkan']"
        outlined
        dense
        hide-details
        class="rounded-lg white mb-2"
        style="max-width: 180px;"
      ></v-select>
    </div>

    <v-row class="mb-4">
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">TRANSAKSI</div>
          <div class="headline font-weight-bold mt-1">{{ filteredOrders.length }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">OMZET</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1">Rp {{ omzet.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
    </v-row>

    <v-card flat outlined class="rounded-xl white">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat riwayat pesanan...</div>
      </div>

      <v-simple-table v-else>
        <thead>
          <tr>
            <th>Invoice</th>
            <th>Waktu</th>
            <th>Pelanggan</th>
            <th>Platform</th>
            <th>Bayar</th>
            <th>Total</th>
            <th>Status</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="filteredOrders.length === 0">
            <td colspan="8" class="text-center py-8 grey--text">Tidak ada transaksi pada rentang tanggal ini.</td>
          </tr>
          <tr v-for="ord in filteredOrders" :key="ord.invoice || ord.id">
            <td class="font-weight-bold">{{ ord.invoice }}</td>
            <td>{{ formatOrderTime(ord) }}</td>
            <td>{{ ord.customer || 'Umum' }}</td>
            <td>{{ ord.platform || 'Offline Store' }}</td>
            <td>{{ ord.method || ord.payment_method || '-' }}</td>
            <td class="font-weight-bold">Rp {{ Number(ord.total || 0).toLocaleString('id-ID') }}</td>
            <td>
              <v-chip
                x-small
                :color="getStatusColor(ord.status).bg"
                :class="getStatusColor(ord.status).text"
                class="font-weight-bold"
              >
                {{ ord.status || 'Selesai' }}
              </v-chip>
            </td>
            <td>
              <v-btn text x-small color="#0f4c3a" class="font-weight-bold" @click="reprint(ord)">Struk</v-btn>
            </td>
          </tr>
        </tbody>
      </v-simple-table>
    </v-card>

    <!-- Template Struk Thermal Tersembunyi (Cetak Ulang langsung dari halaman Pesanan) -->
    <div style="display: none;">
      <div id="OrderReceiptPrint">
        <div id="invoice-POS-order">
          <center>
            <h3>{{ setting.store_name }}</h3>
            <p>{{ setting.location_store }}<br/>Telp: {{ setting.contact }}</p>
          </center>
          <hr/>
          <p v-if="receiptOrder">
            No: {{ receiptOrder.invoice }}<br/>
            Waktu: {{ formatOrderTime(receiptOrder) }}<br/>
            Platform: {{ receiptOrder.platform || 'Offline Store' }} · {{ receiptOrder.method || receiptOrder.payment_method }}
          </p>
          <table v-if="receiptOrder && receiptOrder.items" style="width: 100%; font-size: 11px;">
            <tr v-for="(item, idx) in receiptOrder.items" :key="item.id || idx">
              <td>{{ item.title || item.name }} x{{ item.quantity }}</td>
              <td style="text-align: right;">{{ (Number(item.price || 0) * Number(item.quantity || 1)).toLocaleString('id-ID') }}</td>
            </tr>
          </table>
          <hr/>
          <div v-if="receiptOrder" style="font-size: 11px; text-align: right;">
            <div>Subtotal: Rp {{ Number(receiptOrder.subtotal || receiptOrder.total || 0).toLocaleString('id-ID') }}</div>
            <div v-if="Number(receiptOrder.discount || 0) > 0">Diskon: -Rp {{ Number(receiptOrder.discount).toLocaleString('id-ID') }}</div>
            <div>PPN ({{ setting.tax }}%): Rp {{ Number(receiptOrder.tax || 0).toLocaleString('id-ID') }}</div>
            <strong>Total: Rp {{ Number(receiptOrder.total || 0).toLocaleString('id-ID') }}</strong>
          </div>
          <center><p style="margin-top: 8px;">{{ setting.receipt_footer }}</p></center>
        </div>
      </div>
    </div>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'OrdersView',
  data() {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().slice(0, 10);
    return {
      startDate: firstDay,
      endDate: lastDay,
      statusFilter: 'Semua status',
      isLoading: false,
      errorMessage: '',
      receiptOrder: null,
    };
  },
  computed: {
    ...mapGetters(['orders', 'setting']),
    filteredOrders() {
      return this.orders.filter((o) => {
        const status = o.status || 'Selesai';
        const matchStatus = this.statusFilter === 'Semua status' || status === this.statusFilter;

        const rawDate = (o.date || o.created_at || '').slice(0, 10);
        const matchStart = !this.startDate || !rawDate || rawDate >= this.startDate;
        const matchEnd = !this.endDate || !rawDate || rawDate <= this.endDate;

        return matchStatus && matchStart && matchEnd;
      });
    },
    omzet() {
      return this.filteredOrders.reduce((s, o) => s + Number(o.total || 0), 0);
    },
  },
  async created() {
    await this.loadOrders();
  },
  methods: {
    async loadOrders() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await Promise.all([
          this.$store.dispatch('fetchOrders'),
          this.$store.dispatch('fetchPosData'),
        ]);
      } catch (err) {
        if (err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat riwayat pesanan dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    formatOrderTime(ord) {
      if (ord.time) return ord.time;
      if (ord.created_at) return String(ord.created_at).replace('T', ' ').slice(0, 16);
      return ord.date || '-';
    },
    getStatusColor(status) {
      if (status === 'Dibatalkan') return { bg: 'red lighten-4', text: 'red--text text--darken-3' };
      if (status === 'Belum Lunas') return { bg: 'amber lighten-4', text: 'amber--text text--darken-4' };
      return { bg: 'green lighten-4', text: 'green--text text--darken-3' };
    },
    reprint(order) {
      this.receiptOrder = order;
      this.$nextTick(() => {
        const divToPrint = document.getElementById('OrderReceiptPrint');
        if (!divToPrint) return;
        const width = this.setting.receipt_width === '80 mm' ? '80mm' : '58mm';
        const win = window.open('', '_blank', 'width=340,height=600');
        win.document.write(`
          <html><head><title>Struk ${order.invoice || ''}</title>
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