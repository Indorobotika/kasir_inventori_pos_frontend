<template>
  <v-container fluid class="pa-3 pa-md-5 analytics-page">
    <!-- Header -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-4 anim-fade-down">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Analitik &amp; Performa Bisnis</h1>
        <div class="caption grey--text text--darken-1">
          Evaluasi tren penjualan bersih, net profit (setelah tax &amp; HPP), jam sibuk, valuasi stok, dan peringatan stok.
        </div>
      </div>
      <div class="d-flex flex-wrap align-center">
        <v-select
          v-model="selectedYear"
          :items="yearOptions"
          outlined
          dense
          hide-details
          class="rounded-lg mr-2 mb-2 mb-sm-0"
          :color="$vuetify.theme.dark ? 'white' : '#0f4c3a'"
          style="width: 105px;"
          @change="loadAnalyticsData"
        ></v-select>
        <v-select
          v-model="period"
          :items="['7 hari', '30 hari', '90 hari']"
          outlined
          dense
          hide-details
          class="rounded-lg mr-2 mb-2 mb-sm-0"
          :color="$vuetify.theme.dark ? 'white' : '#0f4c3a'"
          style="width: 115px;"
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
            <div
              class="caption mt-1"
              :class="kpiData.transactions_growth >= 0 ? 'green--text text--lighten-3' : 'red--text text--lighten-3'"
            >
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
            <div class="caption grey--text text--lighten-3 mt-1">
              Hari ini: Rp {{ todayData.avg_basket.toLocaleString('id-ID') }}
            </div>
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
          <div class="caption grey--text mt-1">
            Bebas tax · Potongan/Pajak: Rp {{ kpiData.total_tax_deduction.toLocaleString('id-ID') }}
          </div>
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
            <span class="caption grey--text font-weight-bold">NET PROFIT PENJUALAN</span>
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
          <div class="caption grey--text mt-1">Harga jual bersih dipotong tax &amp; HPP</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3" class="mb-3 mb-md-0 anim-stagger" style="--stagger: 4;">
        <v-card flat outlined class="pa-4 rounded-xl h-100 kpi-card" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">NET MARGIN</div>
          <div
            class="headline font-weight-bold mt-2 tabular-num"
            :class="kpiData.margin_percent >= 30 ? 'teal--text text--lighten-2' : 'orange--text text--lighten-2'"
          >
            {{ kpiData.margin_percent }}%
          </div>
          <div class="caption grey--text mt-1">Target sehat F&amp;B/Retail: &ge; 30%</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- GRAFIK TREN BULANAN 12 BULAN DALAM 1 TAHUN -->
    <v-card flat outlined class="pa-4 pa-md-5 rounded-xl mb-4 kpi-card anim-fade-up" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div class="d-flex flex-wrap justify-space-between align-center mb-3">
        <div class="mb-2 mb-md-0">
          <div class="subtitle-1 font-weight-bold">Grafik Tren Bulanan Tahun {{ selectedYear }}</div>
          <div class="caption grey--text">
            Keuntungan penjualan (Net Profit = Harga Jual Bersih &minus; Tax &minus; HPP Produk/Bahan Baku) per bulan
          </div>
        </div>
        <div class="d-flex flex-wrap align-center">
          <v-btn-toggle v-model="monthlyMetric" mandatory dense color="#0f4c3a" class="rounded-lg mr-2 mb-1 mb-sm-0">
            <v-btn small value="net_profit">Net Profit</v-btn>
            <v-btn small value="net_sales">Penjualan Bersih</v-btn>
            <v-btn small value="total_cost">HPP</v-btn>
          </v-btn-toggle>
          <v-select
            v-model="selectedYear"
            :items="yearOptions"
            outlined
            dense
            hide-details
            class="rounded-lg"
            style="width: 100px;"
            @change="loadAnalyticsData"
          ></v-select>
        </div>
      </div>

      <!-- Ringkasan Tahunan -->
      <v-row class="mb-3">
        <v-col cols="12" sm="4" class="py-1">
          <v-sheet :color="$vuetify.theme.dark ? '#282828' : '#f4f8f6'" class="pa-3 rounded-xl">
            <div class="caption grey--text">TOTAL NET PROFIT ({{ selectedYear }})</div>
            <div class="subtitle-1 font-weight-bold teal--text text--lighten-2 tabular-num">
              Rp {{ annualTotals.net_profit.toLocaleString('id-ID') }}
            </div>
          </v-sheet>
        </v-col>
        <v-col cols="12" sm="4" class="py-1">
          <v-sheet :color="$vuetify.theme.dark ? '#282828' : '#fafafa'" class="pa-3 rounded-xl">
            <div class="caption grey--text">TOTAL PENJUALAN BERSIH ({{ selectedYear }})</div>
            <div class="subtitle-1 font-weight-bold tabular-num">
              Rp {{ annualTotals.net_sales.toLocaleString('id-ID') }}
            </div>
          </v-sheet>
        </v-col>
        <v-col cols="12" sm="4" class="py-1">
          <v-sheet :color="$vuetify.theme.dark ? '#282828' : '#fafafa'" class="pa-3 rounded-xl">
            <div class="caption grey--text">BULAN TERTINGGI ({{ bestMonth.label }})</div>
            <div class="subtitle-1 font-weight-bold orange--text text--darken-2 tabular-num">
              Rp {{ Number(bestMonth[monthlyMetric] || 0).toLocaleString('id-ID') }}
            </div>
          </v-sheet>
        </v-col>
      </v-row>

      <!-- Batang 12 Bulan Responsif dengan Tooltip -->
      <div style="overflow-x: auto; white-space: nowrap;">
        <div class="d-flex align-end justify-space-between pt-5 px-2" style="height: 185px; min-width: 620px;">
          <div
            v-for="(m, idx) in formattedMonthlyTrend"
            :key="m.month"
            class="d-flex flex-column align-center mx-1"
            style="min-width: 42px; flex: 1;"
          >
            <div class="caption font-weight-bold mb-1 tabular-num" style="font-size: 10px;">
              {{ m.value !== 0 ? formatCompactRp(m.value) : '' }}
            </div>
            <v-tooltip top>
              <template v-slot:activator="{ on, attrs }">
                <div
                  v-bind="attrs"
                  v-on="on"
                  class="rounded-t-lg peak-bar"
                  :style="{
                    width: '100%',
                    maxWidth: '34px',
                    height: (barsAnimated ? Math.max(8, m.heightPercent) : 8) + 'px',
                    backgroundColor: m.value < 0 ? '#e53935' : m.barColor,
                    opacity: m.value === 0 ? 0.22 : 1,
                    transitionDelay: (idx * 30) + 'ms'
                  }"
                ></div>
              </template>
              <div>
                <div class="font-weight-bold">{{ m.label }} {{ selectedYear }} ({{ m.transactions }} order)</div>
                <div>Penjualan Bersih (non-tax): Rp {{ m.net_sales.toLocaleString('id-ID') }}</div>
                <div>HPP Produk/Bahan: Rp {{ m.total_cost.toLocaleString('id-ID') }}</div>
                <div class="font-weight-bold">Net Profit: Rp {{ m.net_profit.toLocaleString('id-ID') }}</div>
              </div>
            </v-tooltip>
            <div class="caption font-weight-medium mt-1" style="font-size: 11px;">
              {{ m.label }}
            </div>
          </div>
        </div>
      </div>
    </v-card>

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
          <div class="subtitle-1 font-weight-bold">Grafik Tren Penjualan &amp; Net Profit Harian</div>
          <div class="caption grey--text">Pergerakan {{ chartMetric === 'total' ? 'omzet' : 'net profit' }} harian dalam {{ period }} terakhir</div>
        </div>
        <div class="d-flex align-center">
          <v-btn-toggle v-model="chartMetric" mandatory dense color="#0f4c3a" class="rounded-lg">
            <v-btn small value="total">Omzet</v-btn>
            <v-btn small value="profit">Net Profit</v-btn>
          </v-btn-toggle>
        </div>
      </div>

      <div v-if="dailyTrend.length === 0" class="text-center py-8 grey--text body-2">
        Belum ada data grafik pada periode ini.
      </div>

      <div v-else>
        <div
          class="d-flex flex-wrap mb-3 pa-3 rounded-xl"
          :style="{ backgroundColor: $vuetify.theme.dark ? '#2d2d2d' : '#f5f5f5' }"
        >
          <div class="mr-6 mb-2 mb-md-0">
            <div class="caption grey--text">
              Puncak {{ chartMetric === 'total' ? 'Omzet' : 'Net Profit' }} ({{ peakDay.label }})
            </div>
            <div class="subtitle-2 font-weight-bold teal--text text--lighten-2 tabular-num">
              Rp {{ Number(peakDay[chartMetric] || 0).toLocaleString('id-ID') }}
            </div>
          </div>
          <div>
            <div class="caption grey--text">
              Rata-rata {{ chartMetric === 'total' ? 'Omzet' : 'Net Profit' }} / Hari
            </div>
            <div class="subtitle-2 font-weight-bold tabular-num">
              Rp {{ dailyAverage.toLocaleString('id-ID') }}
            </div>
          </div>
        </div>

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
              <span>
                Jam {{ String(h.hour).padStart(2, '0') }}:00 · {{ h.count }} transaksi (Rp {{ h.total.toLocaleString('id-ID') }})
              </span>
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
                  <span class="teal--text text--lighten-2 font-weight-medium">
                    Laba Rp {{ Number(item.profit || 0).toLocaleString('id-ID') }}
                  </span>
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

const DEFAULT_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

export default {
  name: 'AnalyticsView',
  data: () => ({
    period: '30 hari',
    selectedYear: new Date().getFullYear(),
    chartMetric: 'total',
    monthlyMetric: 'net_profit',
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
    rafIds: [],
    requestSeq: 0,
  }),
  computed: {
    periodDays() {
      return parseInt(this.period, 10) || 30;
    },
    chartKey() {
      return `${this.periodDays}-${this.chartMetric}-${this.chartNonce}`;
    },
    yearOptions() {
      const currentYr = new Date().getFullYear();
      const fromApi = this.analyticsData && Array.isArray(this.analyticsData.available_years)
        ? this.analyticsData.available_years.map((y) => Number(y))
        : [];
      const merged = Array.from(new Set([currentYr, this.selectedYear, ...fromApi])).filter(Boolean);
      return merged.sort((a, b) => b - a);
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
        total_tax_deduction: Number(kpi.total_tax_deduction || 0),
        items_sold: Number(kpi.items_sold || 0),
        gross_profit: Number(kpi.gross_profit || 0),
        profit_growth: Number(kpi.profit_growth || 0),
        margin_percent: Number(kpi.margin_percent || 0),
        avg_transaction: Number(kpi.avg_transaction || 0),
        total_bill: Number(kpi.total_bill || 0),
      };
    },
    monthlyTrend() {
      if (this.analyticsData && Array.isArray(this.analyticsData.monthly_trend) && this.analyticsData.monthly_trend.length > 0) {
        return this.analyticsData.monthly_trend.map((m, idx) => ({
          month: Number(m.month || idx + 1),
          label: m.label || DEFAULT_MONTHS[idx] || `Bln ${idx + 1}`,
          transactions: Number(m.transactions || 0),
          net_sales: Number(m.net_sales || 0),
          total_cost: Number(m.total_cost || 0),
          net_profit: Number(m.net_profit || 0),
        }));
      }
      return DEFAULT_MONTHS.map((label, idx) => ({
        month: idx + 1,
        label,
        transactions: 0,
        net_sales: 0,
        total_cost: 0,
        net_profit: 0,
      }));
    },
    annualTotals() {
      return this.monthlyTrend.reduce(
        (acc, m) => {
          acc.net_sales += m.net_sales;
          acc.total_cost += m.total_cost;
          acc.net_profit += m.net_profit;
          return acc;
        },
        { net_sales: 0, total_cost: 0, net_profit: 0 }
      );
    },
    bestMonth() {
      if (this.monthlyTrend.length === 0) {
        return { label: '-', net_profit: 0, net_sales: 0, total_cost: 0 };
      }
      return [...this.monthlyTrend].sort(
        (a, b) => Number(b[this.monthlyMetric] || 0) - Number(a[this.monthlyMetric] || 0)
      )[0];
    },
    formattedMonthlyTrend() {
      const metric = this.monthlyMetric;
      const maxAbs = Math.max(
        ...this.monthlyTrend.map((m) => Math.abs(Number(m[metric] || 0))),
        0
      );
      const colorMap = {
        net_profit: '#0f4c3a',
        net_sales: '#1976d2',
        total_cost: '#f5820d',
      };

      return this.monthlyTrend.map((m) => {
        const val = Number(m[metric] || 0);
        return {
          ...m,
          value: val,
          heightPercent: maxAbs > 0 ? Math.round((Math.abs(val) / maxAbs) * 115) : 0,
          barColor: colorMap[metric] || '#0f4c3a',
        };
      });
    },
    inventoryValuation() {
      const val = this.analyticsData && this.analyticsData.inventory_valuation
        ? this.analyticsData.inventory_valuation
        : {};
      return {
        total_valuation: Number(val.total_valuation || 0),
        raw_material_valuation: Number(val.raw_material_valuation || 0),
        raw_material_count: Number(val.raw_material_count || 0),
        non_recipe_product_valuation: Number(val.non_recipe_product_valuation || 0),
        non_recipe_product_count: Number(val.non_recipe_product_count || 0),
      };
    },
    dailyTrend() {
      return this.analyticsData && Array.isArray(this.analyticsData.daily_trend)
        ? this.analyticsData.daily_trend
        : [];
    },
    chartValues() {
      return this.dailyTrend.map((d) => Number(d[this.chartMetric] || 0));
    },
    peakDay() {
      if (this.dailyTrend.length === 0) return { label: '-', total: 0, profit: 0 };
      return [...this.dailyTrend].sort(
        (a, b) => Number(b[this.chartMetric] || 0) - Number(a[this.chartMetric] || 0)
      )[0];
    },
    dailyAverage() {
      if (this.dailyTrend.length === 0) return 0;
      const sum = this.chartValues.reduce((a, b) => a + b, 0);
      return Math.round(sum / this.dailyTrend.length);
    },
    peakHours() {
      return this.analyticsData && Array.isArray(this.analyticsData.peak_hours)
        ? this.analyticsData.peak_hours
        : [];
    },
    formattedHours() {
      const mapHours = {};
      let maxCount = 0;
      let startHour = 8;
      let endHour = 22;

      this.peakHours.forEach((h) => {
        const hourNum = Number(h.hour);
        const countNum = Number(h.count || 0);
        const totalNum = Number(h.total || 0);
        mapHours[hourNum] = { count: countNum, total: totalNum };
        if (countNum > maxCount) maxCount = countNum;
        if (countNum > 0 && hourNum < startHour) startHour = hourNum;
        if (countNum > 0 && hourNum > endHour) endHour = hourNum;
      });

      const hours = [];
      for (let i = startHour; i <= endHour; i++) {
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
      return this.analyticsData && Array.isArray(this.analyticsData.top_products)
        ? this.analyticsData.top_products
        : [];
    },
    categoryBreakdown() {
      const list = this.analyticsData && Array.isArray(this.analyticsData.category_share)
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
      const list = this.analyticsData && Array.isArray(this.analyticsData.payment_methods)
        ? this.analyticsData.payment_methods
        : [];
      const totalPayment = list.reduce((sum, item) => sum + Number(item.total || 0), 0);

      return list.map((item) => {
        const total = Number(item.total || 0);
        return {
          method: item.payment_method || 'Lainnya',
          total,
          count: Number(item.count || 0),
          percent: totalPayment > 0 ? Math.round((total / totalPayment) * 100) : 0,
        };
      });
    },
    platformBreakdown() {
      return this.analyticsData && Array.isArray(this.analyticsData.platform_share)
        ? this.analyticsData.platform_share
        : [];
    },
    lowStocks() {
      return this.analyticsData && Array.isArray(this.analyticsData.low_stocks)
        ? this.analyticsData.low_stocks
        : [];
    },
    lowRetailProducts() {
      return this.analyticsData && Array.isArray(this.analyticsData.low_retail_products)
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
    formatCompactRp(val) {
      const num = Number(val || 0);
      const abs = Math.abs(num);
      const sign = num < 0 ? '-' : '';
      if (abs >= 1000000) {
        return `${sign}${(abs / 1000000).toFixed(1).replace(/\.0$/, '')}jt`;
      }
      if (abs >= 1000) {
        return `${sign}${Math.round(abs / 1000)}rb`;
      }
      return `${sign}${abs}`;
    },
    clearAnimations() {
      if (Array.isArray(this.rafIds)) {
        this.rafIds.forEach((id) => cancelAnimationFrame(id));
      }
      this.rafIds = [];
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
        const eased = 1 - Math.pow(1 - progress, 3);
        this[propName] = Math.round(startValue + (endValue - startValue) * eased);

        if (progress < 1) {
          const rafId = requestAnimationFrame(step);
          this.rafIds.push(rafId);
        } else {
          this[propName] = endValue;
        }
      };

      const rafId = requestAnimationFrame(step);
      this.rafIds.push(rafId);
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
      const seq = ++this.requestSeq;
      this.isLoading = true;
      this.errorMessage = '';
      try {
        const res = await apiClient.get('/analytics/dashboard', {
          params: {
            days: this.periodDays,
            year: this.selectedYear,
            _t: Date.now(),
          },
        });
        if (seq !== this.requestSeq) return;

        this.analyticsData = res && res.data && res.data.data ? res.data.data : (res ? res.data : null);
        this.triggerVisualAnimations();
      } catch (err) {
        if (seq !== this.requestSeq) return;

        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          const serverMsg = err && err.response && err.response.data && err.response.data.message;
          this.errorMessage = serverMsg || 'Gagal memuat data analitik dari server.';
        }
      } finally {
        if (seq === this.requestSeq) {
          this.isLoading = false;
        }
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

.anim-fade-down {
  animation: fadeDown 0.4s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-fade-up {
  animation: fadeUp 0.45s cubic-bezier(0.22, 1, 0.36, 1) both;
}

.anim-stagger {
  animation: fadeUp 0.45s cubic-bezier(0.22, 1, 0.36, 1) both;
  animation-delay: calc(var(--stagger, 0) * 65ms);
}

@keyframes fadeDown {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.kpi-card {
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1), border-color 0.2s ease, box-shadow 0.2s ease;
}

.kpi-card:hover {
  transform: translateY(-2px);
  border-color: #0f4c3a !important;
  box-shadow: 0 8px 18px rgba(15, 76, 58, 0.08);
}

.stat-tile,
.stat-tile-light {
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1);
}

.stat-tile:hover,
.stat-tile-light:hover {
  transform: translateY(-2px);
}

.live-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #ffc107;
  display: inline-block;
  animation: livePulse 1.8s ease-in-out infinite;
}

@keyframes livePulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.55);
  }
  50% {
    opacity: 0.7;
    transform: scale(1.18);
    box-shadow: 0 0 0 5px rgba(255, 193, 7, 0);
  }
}

.peak-bar {
  transition: height 0.55s cubic-bezier(0.22, 1, 0.36, 1), transform 0.16s ease, opacity 0.25s ease;
  cursor: pointer;
}

.peak-bar:hover {
  transform: scaleY(1.06);
  filter: brightness(1.08);
}

.product-row {
  transition: background-color 0.18s ease, transform 0.18s ease;
}

.product-row:hover {
  transform: translateX(3px);
}

.spin-refresh {
  animation: spin 0.9s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
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
  .anim-fade-down,
  .anim-fade-up,
  .anim-stagger,
  .live-dot,
  .spin-refresh {
    animation: none !important;
  }
  .kpi-card,
  .stat-tile,
  .stat-tile-light,
  .peak-bar,
  .product-row {
    transition: none !important;
  }
}
</style>