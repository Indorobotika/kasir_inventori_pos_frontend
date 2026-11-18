<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Bahan Baku</h1>
        <div class="caption grey--text text--darken-1">Stok bahan untuk produk produksi sendiri, plus stok opname.</div>
      </div>
      <v-btn color="#0f4c3a" dark rounded depressed @click="openAddDialog">
        <v-icon left small>mdi-plus</v-icon> Bahan Baru
      </v-btn>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <!-- Kotak Pencarian Bahan Baku -->
    <v-card flat outlined class="rounded-xl pa-3 mb-4" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <v-text-field
        v-model="searchQuery"
        label="Cari nama bahan baku..."
        prepend-inner-icon="mdi-magnify"
        outlined
        dense
        clearable
        hide-details
        class="rounded-lg"
      ></v-text-field>
    </v-card>

    <!-- Tabel Daftar Bahan Baku dengan Wrapper Scroll Horizontal untuk Mobile -->
    <v-card flat outlined class="rounded-xl overflow-hidden" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat daftar bahan baku...</div>
      </div>

      <div v-else style="overflow-x: auto;">
        <v-simple-table style="min-width: 650px;">
          <thead>
            <tr>
              <th>Bahan</th>
              <th>Stok</th>
              <th>Min.</th>
              <th>Harga Beli</th>
              <th>Status</th>
              <th class="text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredRawMaterials.length === 0">
              <td colspan="6" class="text-center py-8 grey--text">Belum ada data bahan baku yang ditemukan.</td>
            </tr>
            <tr v-for="rm in filteredRawMaterials" :key="rm.id">
              <td class="font-weight-bold">{{ rm.name }}</td>
              <td>{{ rm.stock }} {{ rm.unit }}</td>
              <td>{{ rm.min_stock }}</td>
              <td>Rp {{ Number(rm.cost_price || 0).toLocaleString('id-ID') }}</td>
              <td>
                <v-chip
                  x-small
                  :color="$vuetify.theme.dark ? (Number(rm.stock) > Number(rm.min_stock) ? 'green darken-4' : 'red darken-4') : (Number(rm.stock) > Number(rm.min_stock) ? 'green lighten-4' : 'red lighten-4')"
                  :class="$vuetify.theme.dark ? (Number(rm.stock) > Number(rm.min_stock) ? 'green--text text--lighten-3' : 'red--text text--lighten-3') : (Number(rm.stock) > Number(rm.min_stock) ? 'green--text text--darken-3' : 'red--text')"
                  class="font-weight-bold"
                >
                  {{ Number(rm.stock) > Number(rm.min_stock) ? 'Aman' : 'Menipis' }}
                </v-chip>
              </td>
              <td class="text-right">
                <v-btn text x-small color="#0f4c3a" @click="openOpname(rm)">Opname</v-btn>
                <v-btn
                  icon
                  x-small
                  color="red"
                  :loading="deletingId === rm.id"
                  @click="deleteMaterial(rm.id)"
                >
                  <v-icon small>mdi-delete-outline</v-icon>
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-simple-table>
      </div>
    </v-card>

    <!-- Dialog Tambah Bahan Baku -->
    <v-dialog v-model="dialogAdd" max-width="420" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Tambah Bahan Baku</h3>
          <v-btn icon small :disabled="isSaving" @click="dialogAdd = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field v-model="form.name" label="Nama Bahan" outlined dense class="rounded-lg mb-1"></v-text-field>
        
        <v-select
          v-model="form.unit"
          :items="unitOptions"
          label="Satuan"
          outlined
          dense
          class="rounded-lg mb-1"
        ></v-select>

        <v-text-field v-model.number="form.stock" label="Stok Awal" type="number" step="0.01" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model.number="form.min_stock" label="Batas Minimum" type="number" step="0.01" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model.number="form.cost_price" label="Harga Beli per Satuan (Rp)" type="number" outlined dense class="rounded-lg mb-3"></v-text-field>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSaving"
          :disabled="!form.name.trim() || !form.unit"
          @click="saveMaterial"
        >
          Simpan Bahan
        </v-btn>
      </v-card>
    </v-dialog>

    <!-- Dialog Opname -->
    <v-dialog v-model="dialogOpname" max-width="360" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="subtitle-1 font-weight-bold">Opname: {{ targetRm && targetRm.name }}</h3>
          <v-btn icon small :disabled="isSavingOpname" @click="dialogOpname = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field
          v-model.number="actualStock"
          label="Stok Fisik Aktual"
          type="number"
          step="0.01"
          outlined
          dense
          class="rounded-lg mb-3"
        ></v-text-field>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSavingOpname"
          @click="saveOpname"
        >
          Simpan Opname
        </v-btn>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

export default {
  name: 'RawMaterialsView',
  data: () => ({
    searchQuery: '',
    dialogAdd: false,
    dialogOpname: false,
    targetRm: null,
    actualStock: 0,
    isLoading: false,
    isSaving: false,
    isSavingOpname: false,
    deletingId: null,
    errorMessage: '',
    unitOptions: ['kg', 'gram', 'liter', 'ml', 'pcs', 'pack', 'box'],
    form: { name: '', unit: 'kg', stock: 0, min_stock: 1, cost_price: 0 },
  }),
  computed: {
    ...mapGetters(['rawMaterials']),
    filteredRawMaterials() {
      if (!this.searchQuery) return this.rawMaterials;
      const q = this.searchQuery.toLowerCase();
      return this.rawMaterials.filter(rm => rm.name.toLowerCase().includes(q));
    }
  },
  async created() {
    await this.loadMaterials();
  },
  methods: {
    async loadMaterials() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data bahan baku dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    openAddDialog() {
      this.form = { name: '', unit: 'kg', stock: 0, min_stock: 1, cost_price: 0 };
      this.dialogAdd = true;
    },
    async saveMaterial() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const payload = {
          name: this.form.name.trim(),
          unit: this.form.unit,
          stock: Number(this.form.stock || 0),
          min_stock: Number(this.form.min_stock || 0),
          cost_price: Number(this.form.cost_price || 0),
        };
        
        await apiClient.post('/raw-materials', payload);
        await this.$store.dispatch('fetchPosData');
        this.dialogAdd = false;
      } catch (err) {
        if (err.response && err.response.data && err.response.data.errors) {
          const errs = err.response.data.errors;
          this.errorMessage = Object.values(errs).flat().join(', ');
        } else {
          this.errorMessage = (err.response && err.response.data && err.response.data.message) || 'Gagal menyimpan bahan baku baru.';
        }
      } finally {
        this.isSaving = false;
      }
    },
    async deleteMaterial(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await apiClient.delete(`/raw-materials/${id}`);
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        this.errorMessage = 'Gagal menghapus bahan baku dari database.';
      } finally {
        this.deletingId = null;
      }
    },
    openOpname(rm) {
      this.targetRm = rm;
      this.actualStock = Number(rm.stock || 0);
      this.dialogOpname = true;
    },
    async saveOpname() {
      this.isSavingOpname = true;
      this.errorMessage = '';
      try {
        await apiClient.post(`/raw-materials/${this.targetRm.id}/opname`, {
          actual_stock: Number(this.actualStock),
        });
        await this.$store.dispatch('fetchPosData');
        this.dialogOpname = false;
      } catch (err) {
        this.errorMessage = 'Gagal menyimpan stok opname bahan baku.';
      } finally {
        this.isSavingOpname = false;
      }
    },
  },
};
</script>