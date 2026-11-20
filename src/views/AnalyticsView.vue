<template>
  <v-container fluid class="pa-3 pa-md-5 analytics-page">
    <!-- Header -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-4 anim-fade-down">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Analitik &amp; Performa Bisnis</h1>
        <div class="caption grey--text text--darken-1">Evaluasi tren penjualan, margin laba, jam sibuk, valuasi stok, dan peringatan stok.</div>
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
          <v-icon small :class="{ 'spin-refresh': isLoading }">mdi-refresh</v-icon>
        </v-btn>
      </div>
    </div>

    <transition name="slide-fade">
      <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
        {{ errorMessage }}
      </v-alert>
    </transition>

    <!-- Ikhtisar Toko Real-Time -->
    <v-card color="#0f4c3a" dark class="rounded-xl pa-4 pa-md-5 mb-5 hero-card anim-fade-up" flat>
      <div class="d-flex justify-space-between align-center mb-4">
        <h3 class="subtitle-1 font-weight-bold mb-0">Ikhtisar Hari Ini</h3>
        <div class="d-flex align-center">
          <span class="live-dot mr-2"></span>
          <span class="caption amber--text font-weight-bold">REAL-TIME</span>
        </div>
      </div>
      <v-row>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl stat-tile">
            <div class="caption grey--text text--lighten-2">PENDAPATAN HARI INI</div>
            <div class="display-1 font-weight-bold amber--text mt-2 tabular-num">
              Rp {{ animatedTodayRevenue.toLocaleString('id-ID') }}
            </div>
            <div class="caption grey--text text--lighten-3 mt-1">{{ todayData.orders }} pesanan selesai</div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl stat-tile">
            <div class="caption grey--text text--lighten-2">TOTAL PESANAN ({{ period.toUpperCase() }})</div>
            <div class="display-1 font-weight-bold amber--text mt-2 tabular-num">
              {{ animatedTransactions }}
            </div>
            <div class="caption mt-1" :class="kpiData.transactions_growth >= 0 ? 'green--text text--lighten-3' : 'red--text text--lighten-3'">
              {{ kpiData.transactions_growth >= 0 ? '▲' : '▼' }} {{ Math.abs(kpiData.transactions_growth) }}% vs periode lalu
            </div>
          </v-sheet>
        </v-col>
        <v-col cols="12" md="4" class="py-2 py-md-3">
          <v-sheet color="#1d5b49" class="pa-4 rounded-xl stat-tile">
            <div class="caption grey--text text--lighten-2">RATA-RATA KERANJANG (AOV)</div>
            <div class="display-1 font-weight-bold amber--text mt-2 tabular-num">
              Rp {{ animatedAvgTransaction.toLocaleString('id-ID') }}
            </div>
            <div class="caption grey--text text--lighten-3 mt-1">Hari ini: Rp {{ todayData.avg_basket.toLocaleString('id-ID') }}</div>
          </v-sheet>
        </v-col>
      </v-row>
    </v-card>

    <!-- 4 KPI Cards dengan Indikator Pertumbuhan -->
    <v-row class="mb-2">
      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0 anim-stagger" style="--stagger: 1;">
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="d-flex justify-space-between align-center">
            <span class="caption grey--text font-weight-bold">PENJUALAN BERSIH</span>
            <v-chip
              x-small
              :color="$vuetify.theme.dark ? (kpiData.net_sales_growth >= 0 ? 'green darken-4' : 'red darken-4') : (kpiData.net_sales_growth >= 0 ? 'green lighten-5' : 'red lighten-5')"
              :class="$vuetify.theme.dark ? (kpiData.net_sales_growth >= 0 ? 'green--text text--lighten-3' : 'red--text text--lighten-3') : (kpiData.net_sales_growth >= 0 ? 'green--text' : 'red--text')"
              class="font-weight-bold"
            >
              {{ kpiData.net_sales_growth >= 0 ? '+' : '' }}{{ kpiData.net_sales_growth }}%
            </v-chip>
          </div>
          <div class="headline font-weight-bold mt-2 tabular-num">
            Rp {{ animatedNetSales.toLocaleString('id-ID') }}
          </div>
          <div class="caption grey--text mt-1">Diskon diberikan: Rp {{ kpiData.total_discount.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0 anim-stagger" style="--stagger: 2;">
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">HARGA POKOK (HPP)</div>
          <div class="headline font-weight-bold mt-2 tabular-num">
            Rp {{ animatedHpp.toLocaleString('id-ID') }}
          </div>
          <div class="caption grey--text mt-1">{{ kpiData.items_sold }} item terjual</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0 anim-stagger" style="--stagger: 3;">
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="d-flex justify-space-between align-center">
            <span class="caption grey--text font-weight-bold">LABA KOTOR</span>
            <v-chip
              x-small
              :color="$vuetify.theme.dark ? (kpiData.profit_growth >= 0 ? 'green darken-4' : 'red darken-4') : (kpiData.profit_growth >= 0 ? 'green lighten-5' : 'red lighten-5')"
              :class="$vuetify.theme.dark ? (kpiData.profit_growth >= 0 ? 'green--text text--lighten-3' : 'red--text text--lighten-3') : (kpiData.profit_growth >= 0 ? 'green--text' : 'red--text')"
              class="font-weight-bold"
            >
              {{ kpiData.profit_growth >= 0 ? '+' : '' }}{{ kpiData.profit_growth }}%
            </v-chip>
          </div>
          <div class="headline font-weight-bold teal--text text--lighten-2 mt-2 tabular-num">
            Rp {{ animatedGrossProfit.toLocaleString('id-ID') }}
          </div>
          <div class="caption grey--text mt-1">Penjualan bersih dikurangi HPP</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0 anim-stagger" style="--stagger: 4;">
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">GROSS MARGIN</div>
          <div class="headline font-weight-bold mt-2 tabular-num" :class="kpiData.margin_percent >= 30 ? 'teal--text text--lighten-2' : 'orange--text text--lighten-2'">
            {{ kpiData.margin_percent }}%
          </div>
          <div class="caption grey--text mt-1">Target sehat F&amp;B/Retail: &ge; 30%</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- VALUASI STOK SAAT INI (BERBASIS HPP) -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4 kpi-card anim-fade-up" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-3">
        <div>
          <div class="subtitle-1 font-weight-bold">Valuasi Stok Saat Ini (Berbasis HPP)</div>
          <div class="caption grey--text">Nilai aset stok aktif saat ini dihitung dari stok &times; HPP (non-resep)</div>
        </div>
        <v-chip
          small
          :color="$vuetify.theme.dark ? 'teal darken-4' : 'teal lighten-5'"
          :class="$vuetify.theme.dark ? 'teal--text text--lighten-3' : 'teal--text'"
          class="font-weight-bold"
        >
          Total: Rp {{ animatedTotalValuation.toLocaleString('id-ID') }}
        </v-chip>
      </div>

      <v-row>
        <v-col cols="12" md="4">
          <v-sheet
            :color="$vuetify.theme.dark ? '#282828' : '#f4f8f6'"
            class="pa-4 rounded-xl h-100 stat-tile-light"
          >
            <div class="caption grey--text font-weight-bold">TOTAL VALUASI STOK</div>
            <div class="headline font-weight-bold teal--text text--lighten-2 mt-1 tabular-num">
              Rp {{ animatedTotalValuation.toLocaleString('id-ID') }}
            </div>
            <div class="caption grey--text mt-1">Gabungan bahan baku &amp; produk non-resep</div>
          </v-sheet>
        </v-col>

        <v-col cols="12" sm="6" md="4">
          <v-sheet
            :color="$vuetify.theme.dark ? '#282828' : '#fafafa'"
            class="pa-4 rounded-xl h-100 stat-tile-light"
          >
            <div class="caption grey--text font-weight-bold">VALUASI BAHAN BAKU</div>
            <div class="title font-weight-bold mt-1 tabular-num">
              Rp {{ inventoryValuation.raw_material_valuation.toLocaleString('id-ID') }}
            </div>
            <div class="caption grey--text mt-1">{{ inventoryValuation.raw_material_count }} item bahan baku</div>
          </v-sheet>
        </v-col>

        <v-col cols="12" sm="6" md="4">
          <v-sheet
            :color="$vuetify.theme.dark ? '#282828' : '#fafafa'"
            class="pa-4 rounded-xl h-100 stat-tile-light"
          >
            <div class="caption grey--text font-weight-bold">VALUASI PRODUK NON-RESEP</div>
            <div class="title font-weight-bold mt-1 tabular-num">
              Rp {{ inventoryValuation.non_recipe_product_valuation.toLocaleString('id-ID') }}
            </div>
            <div class="caption grey--text mt-1">{{ inventoryValuation.non_recipe_product_count }} produk non-resep</div>
          </v-sheet>
        </v-col>
      </v-row>
    </v-card>

    <!-- GRAFIK TREN HARIAN (OMZET VS LABA) -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4 kpi-card anim-fade-up" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-3">
        <div class="mb-2 mb-md-0">
          <div class="subtitle-1 font-weight-bold">Grafik Tren Penjualan &amp; Laba Harian</div>
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
            <div class="subtitle-2 font-weight-bold teal--text text--lighten-2 tabular-num">
              Rp {{ Number(peakDay[chartMetric] || 0).toLocaleString('id-ID') }}
            </div>
          </div>
          <div>
            <div class="caption grey--text">Rata-rata / Hari</div>
            <div class="subtitle-2 font-weight-bold tabular-num">
              Rp {{ dailyAverage.toLocaleString('id-ID') }}
            </div>
          </div>
        </div>

        <!-- Vuetify Sparkline Chart -->
        <transition name="fade-fast" mode="out-in">
          <v-sparkline
            :key="chartKey"
            :value="chartValues"
            :gradient="chartMetric === 'total' ? ['#0f4c3a', '#43a047'] : ['#f5820d', '#ffb74d']"
            :smooth="10"
            :padding="12"
            :line-width="3"
            stroke-linecap="round"
            gradient-direction="top"
            type="trend"
            auto-draw
            :auto-draw-duration="750"
            height="110"
          ></v-sparkline>
        </transition>

        <!-- Label Sumbu X (Tanggal) -->
        <div class="d-flex justify-space-between caption grey--text px-2 mt-1">
          <span>{{ dailyTrend[0] ? dailyTrend[0].label : '' }}</span>
          <span v-if="dailyTrend.length > 2">{{ dailyTrend[Math.floor(dailyTrend.length / 2)].label }}</span>
          <span>{{ dailyTrend[dailyTrend.length - 1] ? dailyTrend[dailyTrend.length - 1].label : '' }}</span>
        </div>
      </div>
    </v-card>

    <!-- GRAFIK BATANG JAM SIBUK (PEAK HOURS) -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4 kpi-card anim-fade-up" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="subtitle-1 font-weight-bold">Distribusi Jam Sibuk (Peak Hours)</div>
      <div class="caption grey--text mb-4">Waktu transaksi paling padat untuk optimasi jadwal operasional</div>

      <div v-if="peakHours.length === 0" class="text-center py-6 grey--text body-2">
        Belum ada data jam transaksi.
      </div>

      <!-- Container scroll horizontal agar ramah layar mobile -->
      <div v-else style="overflow-x: auto; white-space: nowrap;">
        <div class="d-flex align-end justify-space-between pt-4 px-2" style="height: 150px; min-width: 550px;">
          <div
            v-for="(h, idx) in formattedHours"
            :key="h.hour"
            class="d-flex flex-column align-center mx-1"
            style="min-width: 32px; flex: 1;"
          >
            <div class="caption font-weight-bold mb-1 tabular-num" style="font-size: 10px;">
              {{ h.count > 0 ? h.count : '' }}
            </div>
            <v-tooltip top>
              <template v-slot:activator="{ on, attrs }">
                <div
                  v-bind="attrs"
                  v-on="on"
                  class="rounded-t-lg peak-bar"
                  :class="{ 'peak-bar--highlight': h.isPeak }"
                  :style="{
                    width: '100%',
                    maxWidth: '28px',
                    height: (barsAnimated ? Math.max(6, h.heightPercent) : 6) + 'px',
                    backgroundColor: h.isPeak ? '#f5820d' : '#0f4c3a',
                    opacity: h.count === 0 ? 0.2 : 1,
                    transitionDelay: (idx * 25) + 'ms'
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
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Produk Terlaris &amp; Profitabilitas</div>
          <div class="caption grey--text mb-3">Top produk &amp; bahan terjual berdasarkan omzet ({{ period }})</div>
          <div v-if="topProducts.length === 0" class="text-center py-6 grey--text body-2">
            Belum ada data penjualan pada periode ini.
          </div>
          <div
            v-for="(item, idx) in topProducts"
            :key="item.unique_key || ((item.source_type || 'prod') + '-' + (item.id || idx))"
            class="d-flex justify-space-between align-center py-2 product-row"
            :style="{ borderBottom: '1px solid ' + ($vuetify.theme.dark ? '#2d2d2d' : '#f0f0f0') }"
          >
            <div class="d-flex align-center">
              <v-avatar
                size="28"
                :color="idx < 3 ? '#0f4c3a' : ($vuetify.theme.dark ? '#2d2d2d' : 'grey lighten-3')"
                :dark="idx < 3"
                class="mr-3 caption font-weight-bold rank-badge"
              >
                {{ idx + 1 }}
              </v-avatar>
              <div>
                <div class="d-flex align-center">
                  <span class="body-2 font-weight-bold text-truncate" style="max-width: 150px;">{{ item.title }}</span>
                  <v-chip
                    v-if="item.source_type === 'raw_material'"
                    x-small
                    :color="$vuetify.theme.dark ? 'teal darken-4' : 'teal lighten-5'"
                    :class="$vuetify.theme.dark ? 'teal--text text--lighten-3' : 'teal--text'"
                    class="font-weight-bold ml-1"
                  >
                    BAHAN
                  </v-chip>
                </div>
                <div class="caption grey--text">
                  {{ Number(item.sold_qty || 0) }} terjual ·
                  <span class="teal--text text--lighten-2 font-weight-medium">Laba Rp {{ Number(item.profit || 0).toLocaleString('id-ID') }}</span>
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="body-2 font-weight-bold tabular-num">Rp {{ Number(item.revenue || 0).toLocaleString('id-ID') }}</div>
              <div class="caption grey--text">
                Margin {{ item.revenue > 0 ? Math.round((item.profit / item.revenue) * 100) : 0 }}%
              </div>
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="6">
        <!-- Penjualan per Kategori -->
        <v-card flat outlined class="pa-4 rounded-xl mb-4 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Penjualan per Kategori</div>
          <div class="caption grey--text mb-3">Kontribusi omzet tiap kategori</div>
          <div v-if="categoryBreakdown.length === 0" class="text-center py-4 grey--text body-2">
            Belum ada data kategori pada periode ini.
          </div>
          <div v-for="cat in categoryBreakdown" :key="cat.name" class="mb-3">
            <div class="d-flex justify-space-between body-2 mb-1">
              <span class="font-weight-medium">{{ cat.name }} ({{ cat.qty }} item)</span>
              <span class="tabular-num">Rp {{ cat.revenue.toLocaleString('id-ID') }} · <strong>{{ cat.percent }}%</strong></span>
            </div>
            <v-progress-linear
              :value="barsAnimated ? cat.percent : 0"
              color="#0f4c3a"
              height="8"
              rounded
            ></v-progress-linear>
          </div>
        </v-card>

        <!-- Platform & Metode Pembayaran -->
        <v-card flat outlined class="pa-4 rounded-xl kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="subtitle-1 font-weight-bold">Channel &amp; Metode Pembayaran</div>
          <div class="caption grey--text mb-3">Komposisi transaksi masuk</div>
          <div v-if="paymentBreakdown.length === 0" class="text-center py-4 grey--text body-2">
            Belum ada transaksi pada periode ini.
          </div>
          <div v-for="pm in paymentBreakdown" :key="pm.method" class="mb-3">
            <div class="d-flex justify-space-between body-2 mb-1">
              <span class="font-weight-medium">{{ pm.method }} ({{ pm.count }}x)</span>
              <span class="tabular-num">Rp {{ pm.total.toLocaleString('id-ID') }} · <strong>{{ pm.percent }}%</strong></span>
            </div>
            <v-progress-linear
              :value="barsAnimated ? pm.percent : 0"
              color="#f5820d"
              height="8"
              rounded
            ></v-progress-linear>
          </div>

          <v-divider v-if="platformBreakdown.length > 0" class="my-3"></v-divider>
          <div v-for="pl in platformBreakdown" :key="pl.platform" class="d-flex justify-space-between caption py-1">
            <span class="font-weight-bold grey--text">{{ pl.platform }}</span>
            <span class="tabular-num">{{ pl.count }} order · Rp {{ Number(pl.total || 0).toLocaleString('id-ID') }}</span>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Peringatan Stok Menipis (Bahan Baku & Produk Retail) -->
    <v-card flat outlined class="pa-4 rounded-xl kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-2">
        <div class="mb-1 mb-md-0">
          <div class="subtitle-1 font-weight-bold">Peringatan Stok Menipis</div>
          <div class="caption grey--text">Bahan baku di bawah batas minimum &amp; produk retail stok &le; 5</div>
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
        <v-chip
          v-for="rm in lowStocks"
          :key="'rm-' + rm.id"
          :color="$vuetify.theme.dark ? 'red darken-4' : 'red lighten-5'"
          :class="$vuetify.theme.dark ? 'red--text text--lighten-3' : 'red--text'"
          class="mr-2 mb-2 font-weight-medium alert-chip"
          small
        >
          <v-icon left x-small :color="$vuetify.theme.dark ? 'red lighten-3' : 'red'">mdi-flask-outline</v-icon>
          {{ rm.name }}: {{ rm.stock }} {{ rm.unit }} (Min: {{ rm.min_stock }})
        </v-chip>
        <v-chip
          v-for="pr in lowRetailProducts"
          :key="'pr-' + pr.id"
          :color="$vuetify.theme.dark ? 'amber darken-4' : 'orange lighten-5'"
          :class="$vuetify.theme.dark ? 'amber--text text--lighten-3' : 'orange--text text--darken-4'"
          class="mr-2 mb-2 font-weight-medium alert-chip"
          small
        >
          <v-icon left x-small :color="$vuetify.theme.dark ? 'amber lighten-3' : 'orange darken-3'">mdi-package-variant</v-icon>
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
    barsAnimated: false,
    chartNonce: 0,
    animatedTodayRevenue: 0,
    animatedTransactions: 0,
    animatedAvgTransaction: 0,
    animatedNetSales: 0,
    animatedHpp: 0,
    animatedGrossProfit: 0,
    animatedTotalValuation: 0,
    _rafIds: [],
  }),
  computed: {
    periodDays() {
      return parseInt(this.period, 10) || 30;
    },
    chartKey() {
      return `${this.periodDays}-${this.chartMetric}-${this.chartNonce}`;
    },
    todayData() {
      const today = this.analyticsData && this.analyticsData.today ? this.analyticsData.today : {};
      return {
        revenue: Number(today.revenue || 0),
        orders: Number(today.orders || 0),
        avg_basket: Number(today.avg_basket || 0),
      };
    },
    kpiData() {
      const kpi = this.analyticsData && this.analyticsData.kpi ? this.analyticsData.kpi : {};
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
    inventoryValuation() {
      const val = this.analyticsData && this.analyticsData.inventory_valuation ? this.analyticsData.inventory_valuation : {};
      return {
        total_valuation: Number(val.total_valuation || 0),
        raw_material_valuation: Number(val.raw_material_valuation || 0),
        raw_material_count: Number(val.raw_material_count || 0),
        non_recipe_product_valuation: Number(val.non_recipe_product_valuation || 0),
        non_recipe_product_count: Number(val.non_recipe_product_count || 0),
      };
    },
    dailyTrend() {
      return (this.analyticsData && Array.isArray(this.analyticsData.daily_trend))
        ? this.analyticsData.daily_trend
        : [];
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
      return (this.analyticsData && Array.isArray(this.analyticsData.peak_hours))
        ? this.analyticsData.peak_hours
        : [];
    },
    formattedHours() {
      const mapHours = {};
      let maxCount = 0;
      this.peakHours.forEach((h) => {
        const hourNum = Number(h.hour);
        const countNum = Number(h.count || 0);
        const totalNum = Number(h.total || 0);
        mapHours[hourNum] = { count: countNum, total: totalNum };
        if (countNum > maxCount) maxCount = countNum;
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
      return (this.analyticsData && Array.isArray(this.analyticsData.top_products))
        ? this.analyticsData.top_products
        : [];
    },
    categoryBreakdown() {
      const list = (this.analyticsData && Array.isArray(this.analyticsData.category_share))
        ? this.analyticsData.category_share
        : [];
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
      const list = (this.analyticsData && Array.isArray(this.analyticsData.payment_methods))
        ? this.analyticsData.payment_methods
        : [];
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
      return (this.analyticsData && Array.isArray(this.analyticsData.platform_share))
        ? this.analyticsData.platform_share
        : [];
    },
    lowStocks() {
      return (this.analyticsData && Array.isArray(this.analyticsData.low_stocks))
        ? this.analyticsData.low_stocks
        : [];
    },
    lowRetailProducts() {
      return (this.analyticsData && Array.isArray(this.analyticsData.low_retail_products))
        ? this.analyticsData.low_retail_products
        : [];
    },
  },
  watch: {
    chartMetric() {
      this.chartNonce += 1;
    },
  },
  async created() {
    await this.loadAnalyticsData();
  },
  beforeDestroy() {
    this.clearAnimations();
  },
  methods: {
    clearAnimations() {
      this._rafIds.forEach((id) => cancelAnimationFrame(id));
      this._rafIds = [];
    },
    tweenNumber(propName, targetValue, duration = 650) {
      const startValue = Number(this[propName] || 0);
      const endValue = Number(targetValue || 0);
      if (startValue === endValue) {
        this[propName] = endValue;
        return;
      }

      const startTime = performance.now();
      const step = (now) => {
        const elapsed = now - startTime;
        const progress = Math.min(1, elapsed / duration);
        // easeOutCubic
        const eased = 1 - Math.pow(1 - progress, 3);
        this[propName] = Math.round(startValue + (endValue - startValue) * eased);

        if (progress < 1) {
          const rafId = requestAnimationFrame(step);
          this._rafIds.push(rafId);
        } else {
          this[propName] = endValue;
        }
      };

      const rafId = requestAnimationFrame(step);
      this._rafIds.push(rafId);
    },
    triggerVisualAnimations() {
      this.clearAnimations();
      this.barsAnimated = false;
      this.chartNonce += 1;

      this.tweenNumber('animatedTodayRevenue', this.todayData.revenue, 700);
      this.tweenNumber('animatedTransactions', this.kpiData.transactions, 550);
      this.tweenNumber('animatedAvgTransaction', this.kpiData.avg_transaction, 700);
      this.tweenNumber('animatedNetSales', this.kpiData.net_sales, 750);
      this.tweenNumber('animatedHpp', this.kpiData.hpp, 700);
      this.tweenNumber('animatedGrossProfit', this.kpiData.gross_profit, 750);
      this.tweenNumber('animatedTotalValuation', this.inventoryValuation.total_valuation, 750);

      this.$nextTick(() => {
        requestAnimationFrame(() => {
          this.barsAnimated = true;
        });
      });
    },
    async loadAnalyticsData() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        const res = await apiClient.get('/analytics/dashboard', {
          params: { days: this.periodDays, _t: Date.now() },
        });
        this.analyticsData = (res && res.data && res.data.data) ? res.data.data : (res ? res.data : null);
        this.triggerVisualAnimations();
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
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

<style scoped>
.analytics-page {
  overflow-x: hidden;
}

.tabular-num {
  font-variant-numeric: tabular-nums;
}

/* Indikator titik live berdenyut halus */
.live-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #ffc107;
  box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.7);
  animation: livePulse 2s infinite;
}

@keyframes livePulse {
  0% {
    transform: scale(0.95);
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.7);
  }
  70% {
    transform: scale(1.05);
    box-shadow: 0 0 0 8px rgba(255, 193, 7, 0);
  }
  100% {
    transform: scale(0.95);
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0);
  }
}

/* Animasi rotasi refresh */
.spin-refresh {
  animation: spinAnim 0.8s linear infinite;
}

@keyframes spinAnim {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Transisi masuk elemen */
.anim-fade-down {
  animation: fadeDown 0.45s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-fade-up {
  animation: fadeUp 0.55s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-stagger {
  animation: fadeUp 0.55s cubic-bezier(0.22, 1, 0.36, 1) both;
  animation-delay: calc(var(--stagger, 0) * 70ms);
}

@keyframes fadeDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(14px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Interaksi hover kartu & tile */
.hero-card {
  transition: transform 0.28s cubic-bezier(0.22, 1, 0.36, 1), box-shadow 0.28s ease;
}

.stat-tile {
  transition: transform 0.25s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.25s ease;
}

.stat-tile:hover {
  transform: translateY(-3px);
}

.kpi-card {
  transition: transform 0.25s cubic-bezier(0.22, 1, 0.36, 1), border-color 0.25s ease, box-shadow 0.25s ease;
}

.kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(15, 76, 58, 0.08);
}

.stat-tile-light {
  transition: transform 0.22s cubic-bezier(0.22, 1, 0.36, 1);
}

.stat-tile-light:hover {
  transform: translateY(-2px);
}

/* Animasi batang jam sibuk */
.peak-bar {
  transition: height 0.65s cubic-bezier(0.22, 1, 0.36, 1), transform 0.2s ease, filter 0.2s ease;
  transform-origin: bottom;
}

.peak-bar:hover {
  transform: scaleY(1.04);
  filter: brightness(1.08);
}

/* Baris produk terlaris */
.product-row {
  transition: transform 0.2s ease, background-color 0.2s ease;
  border-radius: 8px;
  padding-left: 4px;
  padding-right: 4px;
}

.product-row:hover {
  transform: translateX(3px);
}

.product-row:hover .rank-badge {
  transform: scale(1.08);
}

.rank-badge {
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1);
}

/* Chip peringatan stok */
.alert-chip {
  transition: transform 0.2s ease;
}

.alert-chip:hover {
  transform: translateY(-2px);
}

/* Transition Vue */
.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.3s ease;
}

.slide-fade-enter,
.slide-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.fade-fast-enter-active,
.fade-fast-leave-active {
  transition: opacity 0.25s ease;
}

.fade-fast-enter,
.fade-fast-leave-to {
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .live-dot,
  .spin-refresh,
  .anim-fade-down,
  .anim-fade-up,
  .anim-stagger {
    animation: none !important;
  }
  .hero-card,
  .stat-tile,
  .kpi-card,
  .stat-tile-light,
  .peak-bar,
  .product-row,
  .rank-badge,
  .alert-chip {
    transition: none !important;
  }
}
</style>