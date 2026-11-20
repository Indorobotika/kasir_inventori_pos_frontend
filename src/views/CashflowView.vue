<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Cashflow</h1>
        <div class="caption grey--text text--darken-1">Catat uang masuk dan keluar di luar transaksi kasir.</div>
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
          <div class="caption grey--text font-weight-bold">KAS MASUK</div>
          <div class="headline font-weight-bold green--text text--darken-3 mt-1">Rp {{ totalIn.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">KAS KELUAR</div>
          <div class="headline font-weight-bold red--text mt-1">Rp {{ totalOut.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="caption grey--text font-weight-bold">SALDO BULAN INI</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1">Rp {{ (totalIn - totalOut).toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
    </v-row>

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
            <tr v-if="cashflowList.length === 0">
              <td colspan="5" class="text-center py-8 grey--text">Belum ada catatan kas bulan ini.</td>
            </tr>
            <tr v-for="item in cashflowList" :key="item.id">
              <td>{{ formatDate(item.transaction_date || item.created_at) }}</td>
              <td>{{ item.category }}</td>
              <td>{{ item.description || '-' }}</td>
              <td class="text-right font-weight-bold" :class="item.type === 'IN' ? 'green--text' : 'red--text'">
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
    dialog: false,
    isLoading: false,
    isSaving: false,
    deletingId: null,
    errorMessage: '',
    form: defaultForm(),
  }),
  computed: {
    ...mapGetters(['cashflows']),
    cashflowList() {
      return Array.isArray(this.cashflows) ? this.cashflows : [];
    },
    totalIn() {
      return this.cashflowList
        .filter((r) => r.type === 'IN')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
    },
    totalOut() {
      return this.cashflowList
        .filter((r) => r.type === 'OUT')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
    },
  },
  watch: {
    month(newVal) {
      if (newVal) {
        this.loadCashflows();
      }
    },
  },
  async created() {
    await this.loadCashflows();
  },
  methods: {
    formatDate(raw) {
      if (!raw) return '-';
      return String(raw).slice(0, 10);
    },
    openAddDialog() {
      this.errorMessage = '';
      this.form = defaultForm();
      this.dialog = true;
    },
    async loadCashflows() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchCashflows', this.month);
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
        const payload = {
          type: this.form.type,
          transaction_date: this.form.transaction_date || getLocalDateString(),
          category: this.form.category.trim(),
          amount: Number(this.form.amount),
        };
        if (this.form.description && this.form.description.trim()) {
          payload.description = this.form.description.trim();
        }

        await apiClient.post('/cashflows', payload);
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