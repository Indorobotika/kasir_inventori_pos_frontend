<template>
  <v-container fluid class="pa-3 pa-md-5">
    <!-- Header -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Analitik & Performa Bisnis</h1>
        <div class="caption grey--text text--darken-1">Evaluasi tren penjualan, margin laba, jam sibuk, dan peringatan stok.</div>
      </div>
      <div class="d-flex align-center">
        <v-select
          v-model="period"
          :items="['7 hari', '30 hari', '90 hari']"
          outlined
          dense
          hide-details
          class="rounded-lg mr-2"
          :color="$vuetify.theme.dark ? 'white' : '#0f4c3a'"
          style="width: 110px;"
          @change="loadAnalyticsData"
        ></v-select>
        <v-btn icon outlined class="rounded-lg" :loading="isLoading" @click="loadAnalyticsData">
          <v-icon small>mdi-refresh</v-icon>
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <!-- Ikhtisar Toko Real-Time -->
    <v-card color="#0f4c3a" dark class="rounded-xl pa-4 pa-md-5 mb-5" flat>
      <div class="d-flex justify-space-between align-center mb-4">
        <h3 class="subtitle-1 font-weight-bold">Ikhtisar Hari Ini</h3>
        <span class="caption amber--text font-weight-bold">● REAL-TIME</span>
      </div>
      <v-row>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">PENDAPATAN HARI INI</div>
            <div class="display-1 font-weight-bold amber--text mt-2">Rp {{ todayData.revenue.toLocaleString('id-ID') }}</div>
            <div class="caption grey--text text--lighten-3 mt-1">{{ todayData.orders }} pesanan selesai</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">TOTAL PESANAN ({{ period.toUpperCase() }})</div>
            <div class="display-1 font-weight-bold amber--text mt-2">{{ kpiData.transactions }}</div>
            <div class="caption mt-1" :class="kpiData.transactions_growth >= 0 ? 'green--text text--lighten-3' : 'red--text text--lighten-3'">
              {{ kpiData.transactions_growth >= 0 ? '▲' : '▼' }} {{ Math.abs(kpiData.transactions_growth) }}% vs periode lalu
            </div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl">
            <div class="caption grey--text text--lighten-2">RATA-RATA KERANJANG (AOV)</div>
            <div class="display-1 font-weight-bold amber--text mt-2">Rp {{ kpiData.avg_transaction.toLocaleString('id-ID') }}</div>
            <div class="caption grey--text text--lighten-3 mt-1">Hari ini: Rp {{ todayData.avg_basket.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
      </v-row>
    </v-card>

    <!-- 4 KPI Cards dengan Indikator Pertumbuhan -->
    <v-row class="mb-2">
      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="d-flex justify-space-between align-center">
            <span class="caption grey--text font-weight-bold">PENJUALAN BERSIH</span>
            <v-chip x-small :color="kpiData.net_sales_growth >= 0 ? 'green lighten-5' : 'red lighten-5'" :class="kpiData.net_sales_growth >= 0 ? 'green--text' : 'red--text'" class="font-weight-bold">
              {{ kpiData.net_sales_growth >= 0 ? '+' : '' }}{{ kpiData.net_sales_growth }}%
            </v-chip>
          </div>
          <div class="headline font-weight-bold mt-2">Rp {{ kpiData.net_sales.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text mt-1">Diskon diberikan: Rp {{ kpiData.total_discount.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">HARGA POKOK (HPP)</div>
          <div class="headline font-weight-bold mt-2">Rp {{ kpiData.hpp.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text mt-1">{{ kpiData.items_sold }} item terjual</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="d-flex justify-space-between align-center">
            <span class="caption grey--text font-weight-bold">LABA KOTOR</span>
            <v-chip x-small :color="kpiData.profit_growth >= 0 ? 'green lighten-5' : 'red lighten-5'" :class="kpiData.profit_growth >= 0 ? 'green--text' : 'red--text'" class="font-weight-bold">
              {{ kpiData.profit_growth >= 0 ? '+' : '' }}{{ kpiData.profit_growth }}%
            </v-chip>
          </div>
          <div class="headline font-weight-bold teal--text text--lighten-2 mt-2">Rp {{ kpiData.gross_profit.toLocaleString('id-ID') }}</div>
          <div class="caption grey--text mt-1">Penjualan bersih dikurangi HPP</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">GROSS MARGIN</div>
          <div class="headline font-weight-bold mt-2" :class="kpiData.margin_percent >= 30 ? 'teal--text text--lighten-2' : 'orange--text text--lighten-2'">
            {{ kpiData.margin_percent }}%
          </div>
          <div class="caption grey--text mt-1">Target sehat F&B/Retail: &ge; 30%</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- GRAFIK TREN HARIAN (OMZET VS LABA) -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-3">
        <div class="mb-2 mb-md-0">
          <div class="subtitle-1 font-weight-bold">Grafik Tren Penjualan & Laba Harian</div>
          <div class="caption grey--text">Pergerakan omzet harian dalam {{ period }} terakhir</div>
        </div>
        <div class="d-flex align-center">
          <v-btn-toggle v-model="chartMetric" mandatory dense color="#0f4c3a" class="rounded-lg">
            <v-btn small value="total">Omzet</v-btn>
            <v-btn small value="profit">Laba Kotor</v-btn>
          </v-btn-toggle>
        </div>
      </div>

      <div v-if="dailyTrend.length === 0" class="text-center py-8 grey--text body-2">
        Belum ada data grafik pada periode ini.
      </div>

      <div v-else>
        <!-- Info Titik Tertinggi & Rata-rata Harian -->
        <div class="d-flex flex-wrap mb-3 pa-3 rounded-xl" :style="{ backgroundColor: $vuetify.theme.dark ? '#2d2d2d' : '#f5f5f5' }">
          <div class="mr-6 mb-2 mb-md-0">
            <div class="caption grey--text">Puncak Harian ({{ peakDay.label }})</div>
            <div class="subtitle-2 font-weight-bold teal--text text--lighten-2">
              Rp {{ Number(peakDay[chartMetric] || 0).toLocaleString('id-ID') }}
            </div>
          </div>
          <div>
            <div class="caption grey--text">Rata-rata / Hari</div>
            <div class="subtitle-2 font-weight-bold">
              Rp {{ dailyAverage.toLocaleString('id-ID') }}
            </div>
          </div>
        </div>

        <!-- Vuetify Sparkline Chart -->
        <v-sparkline
          :value="chartValues"
          :gradient="chartMetric === 'total' ? ['#0f4c3a', '#43a047'] : ['#f5820d', '#ffb74d']"
          :smooth="8"
          :padding="12"
          :line-width="3"
          stroke-linecap="round"
          gradient-direction="top"
          type="trend"
          auto-draw
          height="110"
        ></v-sparkline>

        <!-- Label Sumbu X (Tanggal) -->
        <div class="d-flex justify-space-between caption grey--text px-2 mt-1">
          <span>{{ dailyTrend[0] ? dailyTrend[0].label : '' }}</span>
          <span v-if="dailyTrend.length > 2">{{ dailyTrend[Math.floor(dailyTrend.length / 2)].label }}</span>
          <span>{{ dailyTrend[dailyTrend.length - 1] ? dailyTrend[dailyTrend.length - 1].label : '' }}</span>
        </div>
      </div>
    </v-card>

    <!-- GRAFIK BATANG JAM SIBUK (PEAK HOURS) -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="subtitle-1 font-weight-bold">Distribusi Jam Sibuk (Peak Hours)</div>
      <div class="caption grey--text mb-4">Waktu transaksi paling padat untuk optimasi jadwal operasional</div>

      <div v-if="peakHours.length === 0" class="text-center py-6 grey--text body-2">
        Belum ada data jam transaksi.
      </div>

      <!-- Container scroll horizontal agar ramah layar mobile -->
      <div v-else style="overflow-x: auto; white-space: nowrap;">
        <div class="d-flex align-end justify-space-between pt-4 px-2" style="height: 150px; min-width: 550px;">
          <div
            v-for="h in formattedHours"
            :key="h.hour"
            class="d-flex flex-column align-center mx-1"
            style="min-width: 32px; flex: 1;"
          >
            <div class="caption font-weight-bold mb-1" style="font-size: 10px;">
              {{ h.count > 0 ? h.count : '' }}
            </div>
            <v-tooltip top>
              <template v-slot:activator="{ on, attrs }">
                <div
                  v-bind="attrs"
                  v-on="on"
                  class="rounded-t-lg transition-swing"
                  :style="{
                    width: '100%',
                    maxWidth: '28px',
                    height: Math.max(6, h.heightPercent) + 'px',
                    backgroundColor: h.isPeak ? '#f5820d' : '#0f4c3a',
                    opacity: h.count === 0 ? 0.2 : 1
                  }"
                ></div>
              </template>
              <span>Jam {{ String(h.hour).padStart(2, '0') }}:00 · {{ h.count }} transaksi (Rp {{ h.total.toLocaleString('id-ID') }})</span>
            </v-tooltip>
            <div class="caption grey--text mt-1" style="font-size: 10px;">
              {{ String(h.hour).padStart(2, '0') }}
            </div>
          </div>
        </div>
      </div>
    </v-card>

    <!-- Grid 2 Kolom: Produk Terlaris & Kategori/Platform -->
    <v-row class="mb-4">
      <v-col cols="12" md="6" class="mb-3 mb-md-0">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Produk Terlaris & Profitabilitas</div>
          <div class="caption grey--text mb-3">Top produk berdasarkan omzet ({{ period }})</div>
          <div v-if="topProducts.length === 0" class="text-center py-6 grey--text body-2">
            Belum ada data penjualan pada periode ini.
          </div>
          <div
            v-for="(item, idx) in topProducts"
            :key="item.id || idx"
            class="d-flex justify-space-between align-center py-2"
            :style="{ borderBottom: '1px solid ' + ($vuetify.theme.dark ? '#2d2d2d' : '#f0f0f0') }"
          >
            <div class="d-flex align-center">
              <v-avatar
                size="28"
                :color="idx < 3 ? '#0f4c3a' : ($vuetify.theme.dark ? '#2d2d2d' : 'grey lighten-3')"
                :dark="idx < 3"
                class="mr-3 caption font-weight-bold"
              >
                {{ idx + 1 }}
              </v-avatar>
              <div>
                <div class="body-2 font-weight-bold text-truncate" style="max-width: 150px;">{{ item.title }}</div>
                <div class="caption grey--text">
                  {{ Number(item.sold_qty || 0) }} terjual ·
                  <span class="teal--text text--lighten-2 font-weight-medium">Laba Rp {{ Number(item.profit || 0).toLocaleString('id-ID') }}</span>
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="body-2 font-weight-bold">Rp {{ Number(item.revenue || 0).toLocaleString('id-ID') }}</div>
              <div class="caption grey--text">
                Margin {{ item.revenue > 0 ? Math.round((item.profit / item.revenue) * 100) : 0 }}%
              </div>
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="6">
        <!-- Penjualan per Kategori -->
        <v-card flat outlined class="pa-4 rounded-xl mb-4" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Penjualan per Kategori</div>
          <div class="caption grey--text mb-3">Kontribusi omzet tiap kategori</div>
          <div v-if="categoryBreakdown.length === 0" class="text-center py-4 grey--text body-2">
            Belum ada data kategori pada periode ini.
          </div>
          <div v-for="cat in categoryBreakdown" :key="cat.name" class="mb-3">
            <div class="d-flex justify-space-between body-2 mb-1">
              <span class="font-weight-medium">{{ cat.name }} ({{ cat.qty }} item)</span>
              <span>Rp {{ cat.revenue.toLocaleString('id-ID') }} · <strong>{{ cat.percent }}%</strong></span>
            </div>
            <v-progress-linear :value="cat.percent" color="#0f4c3a" height="8" rounded></v-progress-linear>
          </div>
        </v-card>

        <!-- Platform & Metode Pembayaran -->
        <v-card flat outlined class="pa-4 rounded-xl" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Channel & Metode Pembayaran</div>
          <div class="caption grey--text mb-3">Komposisi transaksi masuk</div>
          <div v-if="paymentBreakdown.length === 0" class="text-center py-4 grey--text body-2">
            Belum ada transaksi pada periode ini.
          </div>
          <div v-for="pm in paymentBreakdown" :key="pm.method" class="mb-3">
            <div class="d-flex justify-space-between body-2 mb-1">
              <span class="font-weight-medium">{{ pm.method }} ({{ pm.count }}x)</span>
              <span>Rp {{ pm.total.toLocaleString('id-ID') }} · <strong>{{ pm.percent }}%</strong></span>
            </div>
            <v-progress-linear :value="pm.percent" color="#f5820d" height="8" rounded></v-progress-linear>
          </div>

          <v-divider v-if="platformBreakdown.length > 0" class="my-3"></v-divider>
          <div v-for="pl in platformBreakdown" :key="pl.platform" class="d-flex justify-space-between caption py-1">
            <span class="font-weight-bold grey--text">{{ pl.platform }}</span>
            <span>{{ pl.count }} order · Rp {{ Number(pl.total || 0).toLocaleString('id-ID') }}</span>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Peringatan Stok Menipis (Bahan Baku & Produk Retail) -->
    <v-card flat outlined class="pa-4 rounded-xl" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-2">
        <div class="mb-1 mb-md-0">
          <div class="subtitle-1 font-weight-bold">Peringatan Stok Menipis</div>
          <div class="caption grey--text">Bahan baku di bawah batas minimum & produk retail stok &le; 5</div>
        </div>
        <div>
          <v-btn text small color="#0f4c3a" to="/bahan-baku" class="mr-1">Bahan Baku</v-btn>
          <v-btn text small color="#0f4c3a" to="/produk">Produk</v-btn>
        </div>
      </div>

      <div v-if="lowStocks.length === 0 && lowRetailProducts.length === 0" class="text-center py-6 grey--text body-2">
        Semua stok bahan baku dan produk retail masih aman.
      </div>
      <div v-else class="mt-3">
        <v-chip v-for="rm in lowStocks" :key="'rm-' + rm.id" color="red lighten-5" class="red--text mr-2 mb-2 font-weight-medium" small>
          <v-icon left x-small color="red">mdi-flask-outline</v-icon>
          {{ rm.name }}: {{ rm.stock }} {{ rm.unit }} (Min: {{ rm.min_stock }})
        </v-chip>
        <v-chip v-for="pr in lowRetailProducts" :key="'pr-' + pr.id" color="orange lighten-5" class="orange--text text--darken-4 mr-2 mb-2 font-weight-medium" small>
          <v-icon left x-small color="orange darken-3">mdi-package-variant</v-icon>
          {{ pr.title }}: sisa {{ pr.stock }} {{ pr.unit || 'pcs' }}
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
    chartMetric: 'total',
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
        net_sales_growth: Number(kpi.net_sales_growth || 0),
        transactions: Number(kpi.transactions || 0),
        transactions_growth: Number(kpi.transactions_growth || 0),
        hpp: Number(kpi.hpp || 0),
        total_discount: Number(kpi.total_discount || 0),
        items_sold: Number(kpi.items_sold || 0),
        gross_profit: Number(kpi.gross_profit || 0),
        profit_growth: Number(kpi.profit_growth || 0),
        margin_percent: Number(kpi.margin_percent || 0),
        avg_transaction: Number(kpi.avg_transaction || 0),
        total_bill: Number(kpi.total_bill || 0),
      };
    },
    dailyTrend() {
      return this.analyticsData?.daily_trend || [];
    },
    chartValues() {
      return this.dailyTrend.map((d) => Number(d[this.chartMetric] || 0));
    },
    peakDay() {
      if (this.dailyTrend.length === 0) return { label: '-', total: 0, profit: 0 };
      return [...this.dailyTrend].sort((a, b) => Number(b[this.chartMetric] || 0) - Number(a[this.chartMetric] || 0))[0];
    },
    dailyAverage() {
      if (this.dailyTrend.length === 0) return 0;
      const sum = this.chartValues.reduce((a, b) => a + b, 0);
      return Math.round(sum / this.dailyTrend.length);
    },
    peakHours() {
      return this.analyticsData?.peak_hours || [];
    },
    formattedHours() {
      const mapHours = {};
      let maxCount = 0;
      this.peakHours.forEach((h) => {
        mapHours[Number(h.hour)] = { count: Number(h.count), total: Number(h.total) };
        if (Number(h.count) > maxCount) maxCount = Number(h.count);
      });

      const hours = [];
      for (let i = 8; i <= 22; i++) {
        const entry = mapHours[i] || { count: 0, total: 0 };
        hours.push({
          hour: i,
          count: entry.count,
          total: entry.total,
          heightPercent: maxCount > 0 ? Math.round((entry.count / maxCount) * 100) : 0,
          isPeak: maxCount > 0 && entry.count === maxCount,
        });
      }
      return hours;
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
          qty: Number(item.qty || 0),
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
    platformBreakdown() {
      return this.analyticsData?.platform_share || [];
    },
    lowStocks() {
      return this.analyticsData?.low_stocks || [];
    },
    lowRetailProducts() {
      return this.analyticsData?.low_retail_products || [];
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