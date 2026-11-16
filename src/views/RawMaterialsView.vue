<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Bahan Baku</h1>
        <div class="caption grey--text text--darken-1">Stok bahan untuk produk produksi sendiri, plus stok opname.</div>
      </div>
      <v-btn color="#0f4c3a" dark rounded depressed @click="dialogAdd = true">
        <v-icon left small>mdi-plus</v-icon> Bahan Baru
      </v-btn>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-card flat outlined class="rounded-xl white">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat daftar bahan baku...</div>
      </div>

      <v-simple-table v-else>
        <thead>
          <tr>
            <th>Bahan</th>
            <th>Stok</th>
            <th>Min.</th>
            <th>Harga beli</th>
            <th>Status</th>
            <th class="text-right">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="rawMaterials.length === 0">
            <td colspan="6" class="text-center py-8 grey--text">Belum ada data bahan baku di database.</td>
          </tr>
          <tr v-for="rm in rawMaterials" :key="rm.id">
            <td class="font-weight-bold">{{ rm.name }}</td>
            <td>{{ rm.stock }} {{ rm.unit }}</td>
            <td>{{ rm.min_stock }}</td>
            <td>Rp {{ Number(rm.cost_price || 0).toLocaleString('id-ID') }}</td>
            <td>
              <v-chip
                x-small
                :color="Number(rm.stock) > Number(rm.min_stock) ? 'green lighten-4' : 'red lighten-4'"
                :class="Number(rm.stock) > Number(rm.min_stock) ? 'green--text text--darken-3' : 'red--text'"
                class="font-weight-bold"
              >
                {{ Number(rm.stock) > Number(rm.min_stock) ? 'Aman' : 'Menipis' }}
              </v-chip>
            </td>
            <td class="text-right">
              <v-btn text x-small @click="openOpname(rm)">Opname</v-btn>
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
    </v-card>

    <v-dialog v-model="dialogAdd" max-width="420" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Tambah Bahan Baku</h3>
          <v-btn icon small :disabled="isSaving" @click="dialogAdd = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field v-model="form.name" label="Nama Bahan" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model="form.unit" label="Satuan (kg, liter, gram, pcs)" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model.number="form.stock" label="Stok Awal" type="number" step="0.01" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model.number="form.min_stock" label="Batas Minimum" type="number" step="0.01" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model.number="form.cost_price" label="Harga Beli per Satuan (Rp)" type="number" outlined dense class="rounded-lg"></v-text-field>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSaving"
          :disabled="!form.name.trim()"
          @click="saveMaterial"
        >
          Simpan Bahan
        </v-btn>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogOpname" max-width="360" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-2">
          <h3 class="subtitle-1 font-weight-bold">Opname Bahan: {{ targetRm && targetRm.name }}</h3>
          <v-btn icon small :disabled="isSavingOpname" @click="dialogOpname = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field
          v-model.number="actualStock"
          label="Stok Fisik Aktual"
          type="number"
          step="0.01"
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

export default {
  name: 'RawMaterialsView',
  data: () => ({
    dialogAdd: false,
    dialogOpname: false,
    targetRm: null,
    actualStock: 0,
    isLoading: false,
    isSaving: false,
    isSavingOpname: false,
    deletingId: null,
    errorMessage: '',
    form: { name: '', unit: 'kg', stock: 5, min_stock: 1, cost_price: 0 },
  }),
  computed: {
    ...mapGetters(['rawMaterials']),
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
    async saveMaterial() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const payload = {
          name: this.form.name.trim(),
          unit: this.form.unit.trim() || 'pcs',
          stock: Number(this.form.stock || 0),
          min_stock: Number(this.form.min_stock || 0),
          cost_price: Number(this.form.cost_price || 0),
        };
        await this.$store.dispatch('createRawMaterial', payload);
        await this.$store.dispatch('fetchPosData');
        this.dialogAdd = false;
        this.form = { name: '', unit: 'kg', stock: 5, min_stock: 1, cost_price: 0 };
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menyimpan bahan baku baru ke database.';
      } finally {
        this.isSaving = false;
      }
    },
    async deleteMaterial(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('removeRawMaterial', id);
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
        await this.$store.dispatch('submitStockOpname', {
          type: 'raw',
          id: this.targetRm.id,
          actualStock: Number(this.actualStock),
        });
        this.dialogOpname = false;
      } catch (err) {
        this.errorMessage = 'Gagal menyimpan stok opname bahan baku ke database.';
      } finally {
        this.isSavingOpname = false;
      }
    },
  },
};
</script>