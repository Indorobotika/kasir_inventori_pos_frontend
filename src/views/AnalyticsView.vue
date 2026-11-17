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
            <div class="display-1 font-weight-bold amber--text mt-3">Rp {{ todayData.revenue.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">PESANAN ({{ period.toUpperCase() }})</div>
            <div class="display-1 font-weight-bold amber--text mt-3">{{ kpiData.transactions }}</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">RATA-RATA / TRANSAKSI</div>
            <div class="display-1 font-weight-bold amber--text mt-3">Rp {{ kpiData.avg_transaction.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
      </v-row>
    </v-card>

    <!-- 4 KPI Cards -->
    <v-row class="mb-4">
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">PENJUALAN BERSIH</div>
          <div class="headline font-weight-bold mt-1">Rp {{ kpiData.net_sales.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">{{ kpiData.transactions }} transaksi</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">HARGA POKOK (HPP)</div>
          <div class="headline font-weight-bold mt-1">Rp {{ kpiData.hpp.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">{{ kpiData.items_sold }} item terjual</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">LABA KOTOR</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1">Rp {{ kpiData.gross_profit.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text">Penjualan - HPP</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">MARGIN</div>
          <div class="headline font-weight-bold mt-1">{{ kpiData.margin_percent }}%</div>
          <div class="caption grey--text">Rata-rata Rp {{ kpiData.avg_transaction.toLocaleString('id-ID') }}/transaksi</div>
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
      <div v-for="(item, idx) in topProducts" :key="item.id || idx" class="d-flex justify-space-between align-center py-2">
        <div class="d-flex align-center">
          <v-avatar size="28" color="grey lighten-3" class="mr-3 caption font-weight-bold">{{ idx + 1 }}</v-avatar>
          <div>
            <div class="body-2 font-weight-bold">{{ item.title }}</div>
            <div class="caption grey--text">{{ Number(item.sold_qty || 0) }} terjual · laba Rp {{ Number(item.profit || 0).toLocaleString('id-ID') }}</div>
          </div>
        </div>
        <div class="body-2 font-weight-bold">Rp {{ Number(item.revenue || 0).toLocaleString('id-ID') }}</div>
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
import apiClient from '@/services/api';

export default {
  name: 'AnalyticsView',
  data: () => ({
    period: '30 hari',
    isLoading: false,
    errorMessage: '',
    analyticsData: null,
  }),
  computed: {
    periodDays() {
      return parseInt(this.period, 10) || 30;
    },
    todayData() {
      const today = this.analyticsData?.today || {};
      return {
        revenue: Number(today.revenue || 0),
        orders: Number(today.orders || 0),
        avg_basket: Number(today.avg_basket || 0),
      };
    },
    kpiData() {
      const kpi = this.analyticsData?.kpi || {};
      return {
        net_sales: Number(kpi.net_sales || 0),
        transactions: Number(kpi.transactions || 0),
        hpp: Number(kpi.hpp || 0),
        items_sold: Number(kpi.items_sold || 0),
        gross_profit: Number(kpi.gross_profit || 0),
        margin_percent: Number(kpi.margin_percent || 0),
        avg_transaction: Number(kpi.avg_transaction || 0),
        total_bill: Number(kpi.total_bill || 0),
      };
    },
    topProducts() {
      return this.analyticsData?.top_products || [];
    },
    categoryBreakdown() {
      const list = this.analyticsData?.category_share || [];
      const totalCategoryRev = list.reduce((sum, item) => sum + Number(item.revenue || 0), 0);

      return list.map((item) => {
        const rev = Number(item.revenue || 0);
        return {
          name: item.name,
          revenue: rev,
          percent: totalCategoryRev > 0 ? Math.round((rev / totalCategoryRev) * 100) : 0,
        };
      });
    },
    paymentBreakdown() {
      const list = this.analyticsData?.payment_methods || [];
      const totalPayment = list.reduce((sum, item) => sum + Number(item.total || 0), 0);

      return list.map((item) => {
        const total = Number(item.total || 0);
        return {
          method: item.payment_method || 'Lainnya',
          total: total,
          count: Number(item.count || 0),
          percent: totalPayment > 0 ? Math.round((total / totalPayment) * 100) : 0,
        };
      });
    },
    lowStocks() {
      return this.analyticsData?.low_stocks || [];
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
        const res = await apiClient.get('/analytics/dashboard', {
          params: { days: this.periodDays },
        });
        this.analyticsData = res.data.data || res.data;
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