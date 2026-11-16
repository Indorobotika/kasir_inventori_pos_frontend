<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Analitik</h1>
        <div class="caption grey--text text--darken-1">Penjualan, laba, kategori, dan stok dalam satu layar.</div>
      </div>
      <div class="d-flex align-center">
        <v-select
          v-model="period"
          :items="['7 hari', '30 hari', '90 hari']"
          outlined
          dense
          hide-details
          class="rounded-lg white mr-2"
          style="width: 120px;"
          @change="loadAnalyticsData"
        ></v-select>
        <v-btn icon outlined class="rounded-lg white" :loading="isLoading" @click="loadAnalyticsData">
          <v-icon small>mdi-refresh</v-icon>
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <!-- Ikhtisar Toko -->
    <v-card color="#0f4c3a" dark class="rounded-xl pa-5 mb-5" flat>
      <div class="d-flex justify-space-between align-center mb-4">
        <h3 class="subtitle-1 font-weight-bold">Ikhtisar toko</h3>
        <span class="caption amber--text">● DIPERBARUI REAL-TIME</span>
      </div>
      <v-row>
        <v-col cols="12" md="4">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">PENDAPATAN HARI INI</div>
            <div class="display-1 font-weight-bold amber--text mt-3">Rp {{ todayOmzet.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">PESANAN ({{ period.toUpperCase() }})</div>
            <div class="display-1 font-weight-bold amber--text mt-3">{{ completedOrders.length }}</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">RATA-RATA / TRANSAKSI</div>
            <div class="display-1 font-weight-bold amber--text mt-3">Rp {{ avgOrder.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
      </v-row>
    </v-card>

    <!-- 4 KPI Cards -->
    <v-row class="mb-4">
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">PENJUALAN BERSIH</div>
          <div class="headline font-weight-bold mt-1">Rp {{ netSales.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">{{ completedOrders.length }} transaksi</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">HARGA POKOK (HPP)</div>
          <div class="headline font-weight-bold mt-1">Rp {{ totalHpp.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">{{ totalItemsSold }} item terjual</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">LABA KOTOR</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1">Rp {{ grossProfit.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">Penjualan - HPP</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">MARGIN</div>
          <div class="headline font-weight-bold mt-1">{{ marginPercent }}%</div>
          <div class="caption grey--text">Rata-rata Rp {{ avgOrder.toLocaleString('id-ID') }}/transaksi</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Produk Terlaris -->
    <v-card flat outlined class="pa-4 rounded-xl white mb-4">
      <div class="subtitle-1 font-weight-bold">Produk terlaris</div>
      <div class="caption grey--text mb-3">Berdasarkan omzet ({{ period }})</div>
      <div v-if="topProducts.length === 0" class="text-center py-4 grey--text body-2">
        Belum ada data penjualan pada periode ini.
      </div>
      <div v-for="(item, idx) in topProducts" :key="item.title" class="d-flex justify-space-between align-center py-2">
        <div class="d-flex align-center">
          <v-avatar size="28" color="grey lighten-3" class="mr-3 caption font-weight-bold">{{ idx + 1 }}</v-avatar>
          <div>
            <div class="body-2 font-weight-bold">{{ item.title }}</div>
            <div class="caption grey--text">{{ item.qty }} terjual · laba Rp {{ item.profit.toLocaleString('id-ID') }}</div>
          </div>
        </div>
        <div class="body-2 font-weight-bold">Rp {{ item.revenue.toLocaleString('id-ID') }}</div>
      </div>
    </v-card>

    <!-- Penjualan per Kategori -->
    <v-card flat outlined class="pa-4 rounded-xl white mb-4">
      <div class="subtitle-1 font-weight-bold">Penjualan per kategori</div>
      <div class="caption grey--text mb-3">Porsi omzet tiap kategori</div>
      <div v-if="categoryBreakdown.length === 0" class="text-center py-4 grey--text body-2">
        Belum ada data kategori pada periode ini.
      </div>
      <div v-for="cat in categoryBreakdown" :key="cat.name" class="mb-3">
        <div class="d-flex justify-space-between body-2 mb-1">
          <span class="font-weight-medium">{{ cat.name }}</span>
          <span>Rp {{ cat.revenue.toLocaleString('id-ID') }} · {{ cat.percent }}%</span>
        </div>
        <v-progress-linear :value="cat.percent" color="#0f4c3a" height="8" rounded></v-progress-linear>
      </div>
    </v-card>

    <!-- Metode Pembayaran -->
    <v-card flat outlined class="pa-4 rounded-xl white mb-4">
      <div class="subtitle-1 font-weight-bold">Metode pembayaran</div>
      <div class="caption grey--text mb-3">Komposisi nilai transaksi</div>
      <div v-if="paymentBreakdown.length === 0" class="text-center py-4 grey--text body-2">
        Belum ada transaksi pada periode ini.
      </div>
      <div v-for="pm in paymentBreakdown" :key="pm.method" class="mb-3">
        <div class="d-flex justify-space-between body-2 mb-1">
          <span class="font-weight-medium">{{ pm.method }}</span>
          <span>Rp {{ pm.total.toLocaleString('id-ID') }} · {{ pm.count }}x</span>
        </div>
        <v-progress-linear :value="pm.percent" color="#f5820d" height="8" rounded></v-progress-linear>
      </div>
    </v-card>

    <!-- Stok Menipis -->
    <v-card flat outlined class="pa-4 rounded-xl white">
      <div class="d-flex justify-space-between align-center">
        <div>
          <div class="subtitle-1 font-weight-bold">Stok menipis</div>
          <div class="caption grey--text">Bahan baku di bawah batas minimum</div>
        </div>
        <v-btn text small color="#0f4c3a" to="/bahan-baku">Kelola</v-btn>
      </div>
      <div v-if="lowStocks.length === 0" class="text-center py-6 grey--text body-2">
        Semua bahan baku masih di atas batas minimum.
      </div>
      <div v-else class="mt-3">
        <v-chip v-for="rm in lowStocks" :key="rm.id" color="red lighten-5" class="red--text mr-2 mb-1" small>
          {{ rm.name }}: {{ rm.stock }} {{ rm.unit }} (Min: {{ rm.min_stock }})
        </v-chip>
      </div>
    </v-card>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

export default {
  name: 'AnalyticsView',
  data: () => ({
    period: '30 hari',
    isLoading: false,
    errorMessage: '',
    dashboardSummary: null,
  }),
  computed: {
    ...mapGetters(['orders', 'rawMaterials']),
    periodDays() {
      return parseInt(this.period, 10) || 30;
    },
    completedOrders() {
      const cutoff = new Date();
      cutoff.setDate(cutoff.getDate() - this.periodDays);
      cutoff.setHours(0, 0, 0, 0);

      return this.orders.filter((o) => {
        if (o.status && o.status !== 'Selesai') return false;
        const rawDate = o.date || o.created_at;
        if (!rawDate) return true;
        const orderDate = new Date(rawDate);
        return !Number.isNaN(orderDate.getTime()) ? orderDate >= cutoff : true;
      });
    },
    todayOmzet() {
      if (this.dashboardSummary && this.dashboardSummary.today_omzet !== undefined) {
        return Number(this.dashboardSummary.today_omzet);
      }
      const todayStr = new Date().toISOString().slice(0, 10);
      return this.orders
        .filter((o) => (!o.status || o.status === 'Selesai') && (o.date || o.created_at || '').slice(0, 10) === todayStr)
        .reduce((s, o) => s + Number(o.total || 0), 0);
    },
    totalOmzet() {
      return this.completedOrders.reduce((s, o) => s + Number(o.total || 0), 0);
    },
    netSales() {
      return this.completedOrders.reduce((s, o) => s + (Number(o.subtotal || o.total || 0) - Number(o.discount || 0)), 0);
    },
    totalHpp() {
      return this.completedOrders.reduce((s, o) => s + Number(o.hpp || 0), 0);
    },
    grossProfit() {
      return this.netSales - this.totalHpp;
    },
    marginPercent() {
      return this.netSales > 0 ? Math.round((this.grossProfit / this.netSales) * 100) : 0;
    },
    avgOrder() {
      return this.completedOrders.length > 0 ? Math.round(this.totalOmzet / this.completedOrders.length) : 0;
    },
    totalItemsSold() {
      return this.completedOrders.reduce(
        (s, o) => s + (o.items || []).reduce((is, i) => is + Number(i.quantity || 0), 0),
        0
      );
    },
    topProducts() {
      const map = {};
      this.completedOrders.forEach((o) => {
        (o.items || []).forEach((i) => {
          const title = i.title || i.name || 'Produk';
          const qty = Number(i.quantity || 0);
          const price = Number(i.price || 0);
          const cost = Number(i.cost || i.cost_price || 0);
          if (!map[title]) map[title] = { title, qty: 0, revenue: 0, profit: 0 };
          map[title].qty += qty;
          map[title].revenue += price * qty;
          map[title].profit += (price - cost) * qty;
        });
      });
      return Object.values(map).sort((a, b) => b.revenue - a.revenue);
    },
    categoryBreakdown() {
      const map = {};
      this.completedOrders.forEach((o) => {
        (o.items || []).forEach((i) => {
          const cat = i.category || 'Lainnya';
          map[cat] = (map[cat] || 0) + Number(i.price || 0) * Number(i.quantity || 0);
        });
      });
      return Object.entries(map).map(([name, revenue]) => ({
        name,
        revenue,
        percent: this.netSales > 0 ? Math.round((revenue / this.netSales) * 100) : 0,
      }));
    },
    paymentBreakdown() {
      const map = {};
      this.completedOrders.forEach((o) => {
        const method = o.method || o.payment_method || 'Lainnya';
        if (!map[method]) map[method] = { method, total: 0, count: 0 };
        map[method].total += Number(o.total || 0);
        map[method].count += 1;
      });
      return Object.values(map).map((pm) => ({
        ...pm,
        percent: this.totalOmzet > 0 ? Math.round((pm.total / this.totalOmzet) * 100) : 0,
      }));
    },
    lowStocks() {
      return this.rawMaterials.filter((r) => Number(r.stock) <= Number(r.min_stock));
    },
  },
  async created() {
    await this.loadAnalyticsData();
  },
  methods: {
    async loadAnalyticsData() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        // Sinkronisasi pesanan & stok bahan baku terbaru dari backend + ringkasan dashboard
        const [dashRes] = await Promise.all([
          apiClient.get('/analytics/dashboard', { params: { days: this.periodDays } }).catch(() => null),
          this.$store.dispatch('fetchOrders'),
          this.$store.dispatch('fetchPosData'),
        ]);

        if (dashRes && dashRes.data) {
          this.dashboardSummary = dashRes.data.data || dashRes.data;
        }
      } catch (err) {
        if (err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data analitik dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>