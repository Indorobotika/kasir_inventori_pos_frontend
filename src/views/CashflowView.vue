<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Cashflow</h1>
        <div class="caption grey--text text--darken-1">
          Pantau uang riil (Cash &amp; Rekening) dari penjualan bersih dan catatan kas.
        </div>
      </div>
      <div class="d-flex flex-wrap align-center">
        <v-text-field
          v-model="month"
          type="month"
          outlined
          dense
          hide-details
          class="rounded-lg mr-2 mb-2 mb-sm-0"
          :class="$vuetify.theme.dark ? '' : 'white'"
          style="width: 170px;"
        ></v-text-field>
        <v-btn color="#0f4c3a" dark rounded depressed @click="openAddDialog">
          <v-icon left small>mdi-plus</v-icon> Catat Kas
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage && !dialog" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-row class="mb-4">
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">KAS MASUK (BERSIH)</div>
          <div class="headline font-weight-bold green--text text--darken-3 mt-1 tabular-num">
            Rp {{ totalIn.toLocaleString('id-ID') }}
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">KAS KELUAR</div>
          <div class="headline font-weight-bold red--text mt-1 tabular-num">
            Rp {{ totalOut.toLocaleString('id-ID') }}
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">SALDO BULAN INI (UANG RIIL)</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1 tabular-num">
            Rp {{ netBalance.toLocaleString('id-ID') }}
          </div>
          <div class="caption grey--text mt-2 d-flex justify-space-between tabular-num">
            <span>Cash: Rp {{ cashBalance.toLocaleString('id-ID') }}</span>
            <span>Rekening: Rp {{ bankBalance.toLocaleString('id-ID') }}</span>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Filter Sumber Dana & Jenis Kas -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-3">
      <v-btn-toggle v-model="sourceFilter" mandatory dense color="#0f4c3a" class="rounded-lg mb-2 mb-sm-0">
        <v-btn value="ALL" small>Semua Dana</v-btn>
        <v-btn value="CASH" small><v-icon left x-small>mdi-cash</v-icon> Cash</v-btn>
        <v-btn value="REKENING" small><v-icon left x-small>mdi-bank-outline</v-icon> Rekening</v-btn>
      </v-btn-toggle>

      <v-btn-toggle v-model="typeFilter" mandatory dense color="#0f4c3a" class="rounded-lg">
        <v-btn value="ALL" small>Semua</v-btn>
        <v-btn value="IN" small>Masuk</v-btn>
        <v-btn value="OUT" small>Keluar</v-btn>
      </v-btn-toggle>
    </div>

    <v-card flat outlined class="rounded-xl overflow-hidden" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat data cashflow...</div>
      </div>

      <div v-else style="overflow-x: auto;">
        <v-simple-table style="min-width: 650px;">
          <thead>
            <tr>
              <th>Tanggal</th>
              <th>Kategori</th>
              <th>Keterangan</th>
              <th class="text-right">Nominal</th>
              <th class="text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="displayedCashflows.length === 0">
              <td colspan="5" class="text-center py-8 grey--text">Belum ada catatan kas yang sesuai filter bulan ini.</td>
            </tr>
            <tr v-for="item in displayedCashflows" :key="item.id">
              <td class="tabular-num">{{ formatDate(item.transaction_date || item.created_at) }}</td>
              <td>
                <span>{{ item.category }}</span>
                <v-chip
                  x-small
                  class="ml-2 font-weight-bold"
                  :color="detectSource(item) === 'CASH' ? 'amber lighten-4' : 'blue lighten-5'"
                  :text-color="detectSource(item) === 'CASH' ? 'amber darken-4' : 'blue darken-3'"
                >
                  {{ detectSource(item) === 'CASH' ? 'Cash' : 'Rekening' }}
                </v-chip>
              </td>
              <td>{{ item.description || '-' }}</td>
              <td
                class="text-right font-weight-bold tabular-num"
                :class="item.type === 'IN' ? 'green--text' : 'red--text'"
              >
                {{ item.type === 'IN' ? '+' : '-' }} Rp {{ Number(item.amount || 0).toLocaleString('id-ID') }}
              </td>
              <td class="text-right">
                <v-btn
                  icon
                  x-small
                  color="red"
                  :loading="deletingId === item.id"
                  @click="deleteRecord(item.id)"
                >
                  <v-icon small>mdi-delete-outline</v-icon>
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-simple-table>
      </div>

      <!-- Footer Paging (10, 20, 50 data) -->
      <div class="d-flex flex-wrap justify-space-between align-center pa-3 border-top">
        <div class="d-flex flex-wrap align-center mb-2 mb-sm-0">
          <span class="caption grey--text mr-2">Tampilkan:</span>
          <v-select
            v-model="perPage"
            :items="[10, 20, 50]"
            outlined
            dense
            hide-details
            class="rounded-lg"
            style="width: 85px;"
            @change="onPerPageChange"
          ></v-select>
          <span class="caption grey--text ml-3 tabular-num">
            Menampilkan {{ rangeText }} dari {{ effectiveTotal }} data
          </span>
        </div>

        <v-pagination
          v-model="page"
          :length="effectiveLastPage"
          :total-visible="5"
          color="#0f4c3a"
          circle
          @input="onPageChange"
        ></v-pagination>
      </div>
    </v-card>

    <v-dialog v-model="dialog" max-width="420" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Catat Kas</h3>
          <v-btn icon small :disabled="isSaving" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-3">
          {{ errorMessage }}
        </v-alert>

        <v-btn-toggle v-model="form.type" mandatory color="#0f4c3a" class="d-flex mb-3">
          <v-btn value="IN" class="flex-grow-1">Kas Masuk</v-btn>
          <v-btn value="OUT" class="flex-grow-1">Kas Keluar</v-btn>
        </v-btn-toggle>

        <div class="caption font-weight-bold mb-1">Sumber Dana Riil:</div>
        <v-btn-toggle v-model="form.source" mandatory color="#0f4c3a" class="d-flex mb-3">
          <v-btn value="CASH" class="flex-grow-1"><v-icon left small>mdi-cash</v-icon> Cash</v-btn>
          <v-btn value="REKENING" class="flex-grow-1"><v-icon left small>mdi-bank-outline</v-icon> Rekening</v-btn>
        </v-btn-toggle>

        <v-text-field
          v-model="form.transaction_date"
          label="Tanggal"
          type="date"
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model="form.category"
          label="Kategori"
          placeholder="Misal: Belanja Operasional, Tambah Modal"
          outlined
          dense
          maxlength="100"
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model.number="form.amount"
          label="Nominal (Rp)"
          type="number"
          min="0"
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model="form.description"
          label="Keterangan"
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSaving"
          :disabled="!form.category || !form.category.trim() || Number(form.amount) <= 0"
          @click="saveRecord"
        >
          Simpan
        </v-btn>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

function getLocalMonthString(dateObj = new Date()) {
  const year = dateObj.getFullYear();
  const month = String(dateObj.getMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

function getLocalDateString(dateObj = new Date()) {
  const year = dateObj.getFullYear();
  const month = String(dateObj.getMonth() + 1).padStart(2, '0');
  const day = String(dateObj.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function defaultForm() {
  return {
    type: 'OUT',
    source: 'CASH',
    transaction_date: getLocalDateString(),
    category: '',
    amount: 0,
    description: '',
  };
}

export default {
  name: 'CashflowView',
  data: () => ({
    month: getLocalMonthString(),
    sourceFilter: 'ALL',
    typeFilter: 'ALL',
    page: 1,
    perPage: 10,
    apiRecords: [],
    apiSummary: null,
    apiPagination: null,
    dialog: false,
    isLoading: false,
    isSaving: false,
    deletingId: null,
    errorMessage: '',
    form: defaultForm(),
  }),
  computed: {
    ...mapGetters(['cashflows']),
    hasApiPaginatedPayload() {
      return Array.isArray(this.apiRecords) && this.apiPagination !== null;
    },
    sourceCashflowList() {
      const base = this.hasApiPaginatedPayload
        ? this.apiRecords
        : (Array.isArray(this.cashflows) ? this.cashflows : []);
      return this.sortDescending(base);
    },
    totalIn() {
      if (this.apiSummary && this.apiSummary.in !== undefined) {
        return Number(this.apiSummary.in || 0);
      }
      return this.sourceCashflowList
        .filter((r) => r.type === 'IN')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
    },
    totalOut() {
      if (this.apiSummary && this.apiSummary.out !== undefined) {
        return Number(this.apiSummary.out || 0);
      }
      return this.sourceCashflowList
        .filter((r) => r.type === 'OUT')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
    },
    netBalance() {
      if (this.apiSummary && this.apiSummary.balance !== undefined) {
        return Number(this.apiSummary.balance || 0);
      }
      return this.totalIn - this.totalOut;
    },
    cashBalance() {
      if (this.apiSummary && this.apiSummary.cash_balance !== undefined) {
        return Number(this.apiSummary.cash_balance || 0);
      }
      return this.sourceCashflowList
        .filter((r) => this.detectSource(r) === 'CASH')
        .reduce((sum, r) => sum + (r.type === 'IN' ? Number(r.amount || 0) : -Number(r.amount || 0)), 0);
    },
    bankBalance() {
      if (this.apiSummary && this.apiSummary.bank_balance !== undefined) {
        return Number(this.apiSummary.bank_balance || 0);
      }
      return this.sourceCashflowList
        .filter((r) => this.detectSource(r) === 'REKENING')
        .reduce((sum, r) => sum + (r.type === 'IN' ? Number(r.amount || 0) : -Number(r.amount || 0)), 0);
    },
    filteredCashflows() {
      return this.sourceCashflowList.filter((item) => {
        const matchType = this.typeFilter === 'ALL' || item.type === this.typeFilter;
        const matchSource = this.sourceFilter === 'ALL' || this.detectSource(item) === this.sourceFilter;
        return matchType && matchSource;
      });
    },
    effectiveTotal() {
      if (this.hasApiPaginatedPayload && this.apiPagination.total !== undefined) {
        return Number(this.apiPagination.total || 0);
      }
      return this.filteredCashflows.length;
    },
    effectiveLastPage() {
      if (this.hasApiPaginatedPayload && this.apiPagination.last_page !== undefined) {
        return Math.max(1, Number(this.apiPagination.last_page || 1));
      }
      return Math.max(1, Math.ceil(this.filteredCashflows.length / this.perPage));
    },
    displayedCashflows() {
      if (this.hasApiPaginatedPayload) {
        return this.filteredCashflows;
      }
      const start = (this.page - 1) * this.perPage;
      return this.filteredCashflows.slice(start, start + this.perPage);
    },
    rangeText() {
      if (this.effectiveTotal === 0 || this.displayedCashflows.length === 0) {
        return '0–0';
      }
      if (this.hasApiPaginatedPayload && this.apiPagination.from !== undefined && this.apiPagination.to !== undefined) {
        return `${this.apiPagination.from}–${this.apiPagination.to}`;
      }
      const start = (this.page - 1) * this.perPage + 1;
      const end = Math.min(this.effectiveTotal, start + this.displayedCashflows.length - 1);
      return `${start}–${end}`;
    },
  },
  watch: {
    month(newVal) {
      if (newVal) {
        this.page = 1;
        this.loadCashflows();
      }
    },
    sourceFilter() {
      this.page = 1;
      if (this.hasApiPaginatedPayload) {
        this.loadCashflows();
      }
    },
    typeFilter() {
      this.page = 1;
      if (this.hasApiPaginatedPayload) {
        this.loadCashflows();
      }
    },
  },
  async created() {
    await this.loadCashflows();
  },
  methods: {
    sortDescending(list) {
      return [...list].sort((a, b) => {
        const dateA = String(a.transaction_date || a.created_at || '').slice(0, 10);
        const dateB = String(b.transaction_date || b.created_at || '').slice(0, 10);
        if (dateA !== dateB) {
          return dateB.localeCompare(dateA);
        }
        const createdA = String(a.created_at || '');
        const createdB = String(b.created_at || '');
        if (createdA !== createdB) {
          return createdB.localeCompare(createdA);
        }
        return Number(b.id || 0) - Number(a.id || 0);
      });
    },
    detectSource(item) {
      const text = `${item.category || ''} ${item.description || ''} ${item.payment_method || ''}`.toLowerCase();
      if (text.includes('cash') || text.includes('tunai')) {
        return 'CASH';
      }
      if (
        text.includes('qris') ||
        text.includes('card') ||
        text.includes('transfer') ||
        text.includes('rekening') ||
        text.includes('bank') ||
        text.includes('shopee') ||
        text.includes('tokopedia')
      ) {
        return 'REKENING';
      }
      return 'CASH';
    },
    formatDate(raw) {
      if (!raw) return '-';
      return String(raw).slice(0, 10);
    },
    openAddDialog() {
      this.errorMessage = '';
      this.form = defaultForm();
      this.dialog = true;
    },
    onPerPageChange() {
      this.page = 1;
      if (this.hasApiPaginatedPayload) {
        this.loadCashflows();
      }
    },
    onPageChange(nextPage) {
      this.page = nextPage || 1;
      if (this.hasApiPaginatedPayload) {
        this.loadCashflows();
      }
    },
    async loadCashflows() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        const res = await apiClient.get('/cashflows', {
          params: {
            month: this.month,
            page: this.page,
            per_page: this.perPage,
            type: this.typeFilter,
            source: this.sourceFilter,
          },
        });
        const payload = res && res.data && res.data.data ? res.data.data : null;

        if (payload && Array.isArray(payload.records) && payload.pagination) {
          this.apiRecords = payload.records;
          this.apiSummary = payload.summary || null;
          this.apiPagination = payload.pagination;
          this.page = Number(payload.pagination.current_page || this.page || 1);
        } else {
          this.apiRecords = [];
          this.apiSummary = null;
          this.apiPagination = null;
          await this.$store.dispatch('fetchCashflows', this.month);
        }
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data cashflow dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    async saveRecord() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const sourceLabel = this.form.source === 'REKENING' ? 'Rekening' : 'Cash';
        const rawDesc = (this.form.description || '').trim();
        const finalDesc = rawDesc
          ? `[${sourceLabel}] ${rawDesc}`
          : `[${sourceLabel}] Catatan kas manual`;

        const payload = {
          type: this.form.type,
          transaction_date: this.form.transaction_date || getLocalDateString(),
          category: this.form.category.trim(),
          amount: Number(this.form.amount),
          description: finalDesc,
        };

        await apiClient.post('/cashflows', payload);
        this.page = 1;
        await this.loadCashflows();

        this.dialog = false;
        this.form = defaultForm();
      } catch (err) {
        if (err && err.response && err.response.data && err.response.data.errors) {
          const errs = err.response.data.errors;
          this.errorMessage = Object.values(errs).flat().join(', ');
        } else {
          this.errorMessage = (err && err.response && err.response.data && err.response.data.message) || 'Gagal menyimpan catatan kas.';
        }
      } finally {
        this.isSaving = false;
      }
    },
    async deleteRecord(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await apiClient.delete(`/cashflows/${id}`);
        await this.loadCashflows();
      } catch (err) {
        this.errorMessage = 'Gagal menghapus catatan kas dari server.';
      } finally {
        this.deletingId = null;
      }
    },
  },
};
</script>

<style scoped>
.tabular-num {
  font-variant-numeric: tabular-nums;
}
</style>