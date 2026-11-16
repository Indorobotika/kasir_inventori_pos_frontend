<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Cashflow</h1>
        <div class="caption grey--text text--darken-1">Catat uang masuk dan keluar di luar transaksi kasir.</div>
      </div>
      <div class="d-flex align-center">
        <v-text-field
          v-model="month"
          type="month"
          outlined
          dense
          hide-details
          class="rounded-lg white mr-2"
          style="width: 170px;"
        ></v-text-field>
        <v-btn color="#0f4c3a" dark rounded depressed @click="dialog = true">
          <v-icon left small>mdi-plus</v-icon> Catat Kas
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-row class="mb-4">
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">KAS MASUK</div>
          <div class="headline font-weight-bold green--text text--darken-3 mt-1">Rp {{ totalIn.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">KAS KELUAR</div>
          <div class="headline font-weight-bold red--text mt-1">Rp {{ totalOut.toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card flat outlined class="pa-4 rounded-xl white">
          <div class="caption grey--text font-weight-bold">SALDO BULAN INI</div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-1">Rp {{ (totalIn - totalOut).toLocaleString('id-ID') }}</div>
        </v-card>
      </v-col>
    </v-row>

    <v-card flat outlined class="rounded-xl white">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat data cashflow...</div>
      </div>

      <v-simple-table v-else>
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
          <tr v-if="filteredCashflows.length === 0">
            <td colspan="5" class="text-center py-8 grey--text">Belum ada catatan kas bulan ini.</td>
          </tr>
          <tr v-for="item in filteredCashflows" :key="item.id">
            <td>{{ formatDate(item.date || item.created_at) }}</td>
            <td>{{ item.category }}</td>
            <td>{{ item.note || item.description || '-' }}</td>
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
    </v-card>

    <v-dialog v-model="dialog" max-width="420" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Catat Kas</h3>
          <v-btn icon small :disabled="isSaving" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-btn-toggle v-model="form.type" mandatory color="#0f4c3a" class="d-flex mb-3">
          <v-btn value="IN" class="flex-grow-1">Kas Masuk</v-btn>
          <v-btn value="OUT" class="flex-grow-1">Kas Keluar</v-btn>
        </v-btn-toggle>

        <v-text-field
          v-model="form.date"
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
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model.number="form.amount"
          label="Nominal (Rp)"
          type="number"
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model="form.note"
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
          :disabled="!form.category || form.amount <= 0"
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

export default {
  name: 'CashflowView',
  data: () => ({
    month: new Date().toISOString().slice(0, 7),
    dialog: false,
    isLoading: false,
    isSaving: false,
    deletingId: null,
    errorMessage: '',
    form: {
      type: 'OUT',
      date: new Date().toISOString().slice(0, 10),
      category: '',
      amount: 0,
      note: '',
    },
  }),
  computed: {
    ...mapGetters(['cashflows']),
    filteredCashflows() {
      if (!this.month) return this.cashflows;
      return this.cashflows.filter((item) => {
        const itemDate = this.formatDate(item.date || item.created_at);
        return itemDate.startsWith(this.month);
      });
    },
    totalIn() {
      return this.filteredCashflows
        .filter((r) => r.type === 'IN')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
    },
    totalOut() {
      return this.filteredCashflows
        .filter((r) => r.type === 'OUT')
        .reduce((s, r) => s + Number(r.amount || 0), 0);
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
    async loadCashflows() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchCashflows');
      } catch (err) {
        if (err.response && err.response.status === 401) {
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
          date: this.form.date || new Date().toISOString().slice(0, 10),
          category: this.form.category,
          amount: Number(this.form.amount),
          note: this.form.note,
          description: this.form.note,
        };
        await this.$store.dispatch('createCashflow', payload);
        this.dialog = false;
        this.form = {
          type: 'OUT',
          date: new Date().toISOString().slice(0, 10),
          category: '',
          amount: 0,
          note: '',
        };
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menyimpan catatan kas ke database.';
      } finally {
        this.isSaving = false;
      }
    },
    async deleteRecord(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('removeCashflow', id);
      } catch (err) {
        this.errorMessage = 'Gagal menghapus catatan kas dari server.';
      } finally {
        this.deletingId = null;
      }
    },
  },
};
</script>