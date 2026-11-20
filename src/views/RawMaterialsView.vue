<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Bahan Baku</h1>
        <div class="caption grey--text text--darken-1">
          Stok bahan untuk produk produksi sendiri, bahan yang dijual di kasir, plus stok opname.
        </div>
      </div>
      <v-btn color="#0f4c3a" dark rounded depressed @click="openAddDialog">
        <v-icon left small>mdi-plus</v-icon> Bahan Baru
      </v-btn>
    </div>

    <v-alert v-if="errorMessage && !dialogAdd && !dialogOpname" type="error" dense outlined class="rounded-lg mb-4">
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
        <v-simple-table style="min-width: 780px;">
          <thead>
            <tr>
              <th style="width: 65px;">Cover</th>
              <th>Bahan</th>
              <th>Stok</th>
              <th>Min.</th>
              <th>Harga Beli</th>
              <th>Jual Kasir</th>
              <th>Status Stok</th>
              <th class="text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredRawMaterials.length === 0">
              <td colspan="8" class="text-center py-8 grey--text">Belum ada data bahan baku yang ditemukan.</td>
            </tr>
            <tr v-for="rm in filteredRawMaterials" :key="rm.id">
              <td>
                <v-avatar size="42" class="grey lighten-3 rounded-lg" tile>
                  <img v-if="rm.cover" :src="rm.cover" alt="Cover" style="object-fit: cover;" />
                  <v-icon v-else small color="grey">mdi-image-outline</v-icon>
                </v-avatar>
              </td>
              <td>
                <div class="font-weight-bold">{{ rm.name }}</div>
                <div class="caption grey--text">{{ rm.unit }}</div>
              </td>
              <td>{{ rm.stock }} {{ rm.unit }}</td>
              <td>{{ rm.min_stock }}</td>
              <td>Rp {{ Number(rm.cost_price || 0).toLocaleString('id-ID') }}</td>
              <td>
                <div v-if="rm.is_sellable">
                  <v-chip x-small color="teal lighten-5" class="teal--text font-weight-bold mb-1">Aktif</v-chip>
                  <div class="caption font-weight-bold">Rp {{ Number(rm.sell_price || 0).toLocaleString('id-ID') }}</div>
                </div>
                <span v-else class="caption grey--text">Tidak Dijual</span>
              </td>
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
                <v-btn text x-small color="#0f4c3a" class="mr-1" @click="openOpname(rm)">Opname</v-btn>
                <v-btn icon x-small color="blue" class="mr-1" @click="openEditDialog(rm)">
                  <v-icon small>mdi-pencil-outline</v-icon>
                </v-btn>
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

    <!-- Dialog Tambah / Edit Bahan Baku -->
    <v-dialog v-model="dialogAdd" max-width="460" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">{{ isEditMode ? 'Edit Bahan Baku' : 'Tambah Bahan Baku' }}</h3>
          <v-btn icon small :disabled="isSaving" @click="dialogAdd = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-3">
          {{ errorMessage }}
        </v-alert>

        <v-text-field v-model="form.name" label="Nama Bahan" outlined dense class="rounded-lg mb-1"></v-text-field>

        <v-select
          v-model="form.unit"
          :items="unitOptions"
          label="Satuan"
          outlined
          dense
          class="rounded-lg mb-1"
        ></v-select>

        <v-text-field v-model.number="form.stock" label="Stok" type="number" step="0.01" min="0" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model.number="form.min_stock" label="Batas Minimum" type="number" step="0.01" min="0" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model.number="form.cost_price" label="Harga Beli per Satuan (Rp)" type="number" min="0" outlined dense class="rounded-lg mb-2"></v-text-field>

        <!-- Pengaturan Jual di Kasir & Gambar -->
        <div class="pa-3 rounded-xl mb-3" :style="{ backgroundColor: $vuetify.theme.dark ? '#2d2d2d' : '#f5f5f5' }">
          <v-switch
            v-model="form.is_sellable"
            label="Aktifkan sebagai item yang dijual di Kasir"
            color="#0f4c3a"
            dense
            hide-details
            class="mt-0 mb-2"
          ></v-switch>

          <div v-if="form.is_sellable">
            <v-text-field
              v-model.number="form.sell_price"
              label="Harga Jual di Kasir (Rp)"
              type="number"
              min="0"
              outlined
              dense
              class="rounded-lg mb-2"
            ></v-text-field>

            <v-select
              v-model="form.category_id"
              :items="categoriesList"
              item-text="name"
              item-value="id"
              label="Kategori Kasir (Opsional)"
              clearable
              outlined
              dense
              class="rounded-lg mb-2"
            ></v-select>

            <div class="caption font-weight-bold mb-1">Gambar Cover Display Kasir</div>
            <div class="d-flex align-center">
              <v-avatar size="52" class="mr-3 grey lighten-3 rounded-lg" tile>
                <img v-if="previewCoverUrl" :src="previewCoverUrl" alt="Preview" style="object-fit: cover;" />
                <v-icon v-else color="grey">mdi-image-outline</v-icon>
              </v-avatar>
              <div class="flex-grow-1">
                <v-file-input
                  v-model="coverFile"
                  label="Pilih gambar (PNG/JPG)"
                  accept="image/png, image/jpeg, image/jpg"
                  outlined
                  dense
                  hide-details
                  class="rounded-lg"
                  prepend-icon="mdi-camera"
                  @change="previewCoverImage"
                ></v-file-input>
                <v-btn
                  v-if="isEditMode && previewCoverUrl"
                  x-small
                  text
                  color="red"
                  class="mt-1 px-0"
                  @click="clearCoverImage"
                >
                  <v-icon left x-small>mdi-close-circle-outline</v-icon> Hapus Gambar
                </v-btn>
              </div>
            </div>
          </div>
        </div>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSaving"
          :disabled="!form.name.trim() || !form.unit || (form.is_sellable && Number(form.sell_price) <= 0)"
          @click="saveMaterial"
        >
          {{ isEditMode ? 'Simpan Perubahan' : 'Simpan Bahan' }}
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

        <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-3">
          {{ errorMessage }}
        </v-alert>

        <v-text-field
          v-model.number="actualStock"
          label="Stok Fisik Aktual"
          type="number"
          step="0.01"
          min="0"
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
    isEditMode: false,
    editMaterialId: null,
    categoriesList: [],
    coverFile: null,
    previewCoverUrl: '',
    removeCover: false,
    unitOptions: ['kg', 'gram', 'liter', 'ml', 'pcs', 'pack', 'box'],
    form: {
      name: '',
      unit: 'kg',
      stock: 0,
      min_stock: 1,
      cost_price: 0,
      is_sellable: false,
      sell_price: 0,
      category_id: null,
    },
  }),
  computed: {
    ...mapGetters(['rawMaterials']),
    filteredRawMaterials() {
      const list = Array.isArray(this.rawMaterials) ? this.rawMaterials : [];
      if (!this.searchQuery) return list;
      const q = this.searchQuery.toLowerCase();
      return list.filter(rm => rm.name && rm.name.toLowerCase().includes(q));
    }
  },
  async created() {
    await Promise.all([
      this.loadCategories(),
      this.loadMaterials(),
    ]);
  },
  methods: {
    normalizeId(val) {
      if (val === null || val === undefined || val === '') return null;
      const num = Number(val);
      return Number.isNaN(num) ? String(val) : num;
    },
    normalizeUnit(unit) {
      const lower = String(unit || 'kg').toLowerCase().trim();
      return this.unitOptions.includes(lower) ? lower : 'kg';
    },
    async loadCategories() {
      try {
        const res = await apiClient.get('/categories', { params: { _t: Date.now() } });
        const raw = res && res.data
          ? (Array.isArray(res.data.data) ? res.data.data : (Array.isArray(res.data) ? res.data : []))
          : [];
        this.categoriesList = raw.map(c => Object.assign({}, c, { id: this.normalizeId(c.id) }));
      } catch (err) {
        this.categoriesList = [];
      }
    },
    async loadMaterials() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data bahan baku dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    openAddDialog() {
      this.isEditMode = false;
      this.editMaterialId = null;
      this.coverFile = null;
      this.previewCoverUrl = '';
      this.removeCover = false;
      this.errorMessage = '';
      this.form = {
        name: '',
        unit: 'kg',
        stock: 0,
        min_stock: 1,
        cost_price: 0,
        is_sellable: false,
        sell_price: 0,
        category_id: null,
      };
      this.dialogAdd = true;
    },
    openEditDialog(rm) {
      this.isEditMode = true;
      this.editMaterialId = rm.id;
      this.coverFile = null;
      this.previewCoverUrl = rm.cover || '';
      this.removeCover = false;
      this.errorMessage = '';
      this.form = {
        name: rm.name || '',
        unit: this.normalizeUnit(rm.unit),
        stock: Number(rm.stock || 0),
        min_stock: Number(rm.min_stock || 0),
        cost_price: Number(rm.cost_price || 0),
        is_sellable: Boolean(rm.is_sellable),
        sell_price: Number(rm.sell_price || 0),
        category_id: rm.category_id ? this.normalizeId(rm.category_id) : null,
      };
      this.dialogAdd = true;
    },
    previewCoverImage(file) {
      this.previewCoverUrl = '';
      if (!file) return;
      this.removeCover = false;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.previewCoverUrl = e.target.result || '';
      };
      reader.readAsDataURL(file);
    },
    clearCoverImage() {
      this.coverFile = null;
      this.previewCoverUrl = '';
      this.removeCover = true;
    },
    async saveMaterial() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const formData = new FormData();
        formData.append('name', this.form.name.trim());
        formData.append('unit', this.normalizeUnit(this.form.unit));
        formData.append('stock', String(Number(this.form.stock || 0)));
        formData.append('min_stock', String(Number(this.form.min_stock || 0)));
        formData.append('cost_price', String(Number(this.form.cost_price || 0)));
        formData.append('is_sellable', this.form.is_sellable ? '1' : '0');
        formData.append('sell_price', this.form.is_sellable ? String(Number(this.form.sell_price || 0)) : '0');
        if (this.form.is_sellable && this.form.category_id) {
          formData.append('category_id', String(this.form.category_id));
        }

        if (this.coverFile) {
          formData.append('cover', this.coverFile);
        } else if (this.isEditMode && this.removeCover) {
          formData.append('remove_cover', '1');
        }

        if (this.isEditMode) {
          await apiClient.post(`/raw-materials/${this.editMaterialId}?_method=PUT`, formData);
        } else {
          await apiClient.post('/raw-materials', formData);
        }

        await this.$store.dispatch('fetchPosData');
        this.dialogAdd = false;
      } catch (err) {
        if (err && err.response && err.response.data && err.response.data.errors) {
          const errs = err.response.data.errors;
          this.errorMessage = Object.values(errs).flat().join(', ');
        } else {
          this.errorMessage = (err && err.response && err.response.data && err.response.data.message) || 'Gagal menyimpan bahan baku.';
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
      this.errorMessage = '';
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