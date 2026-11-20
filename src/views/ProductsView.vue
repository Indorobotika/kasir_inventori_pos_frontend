<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Produk</h1>
        <div class="caption grey--text text--darken-1">Produk retail dan produksi sendiri, lengkap dengan resep dan gambar cover display.</div>
      </div>
      <div class="d-flex align-center">
        <v-btn outlined rounded class="mr-2" :color="$vuetify.theme.dark ? 'white' : ''" @click="dialogCat = true">Kategori</v-btn>
        <v-btn color="#0f4c3a" dark rounded depressed @click="openAddDialog">
          <v-icon left small>mdi-plus</v-icon> Produk Baru
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <!-- Kotak Pencarian Produk -->
    <v-card flat outlined class="rounded-xl pa-3 mb-4" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <v-text-field
        v-model="searchQuery"
        label="Cari nama produk atau SKU..."
        prepend-inner-icon="mdi-magnify"
        outlined
        dense
        clearable
        hide-details
        class="rounded-lg"
      ></v-text-field>
    </v-card>

    <!-- Tabel Daftar Produk -->
    <v-card flat outlined class="rounded-xl overflow-hidden" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat daftar produk...</div>
      </div>

      <div v-else style="overflow-x: auto;">
        <v-simple-table style="min-width: 750px;">
          <thead>
            <tr>
              <th style="width: 70px;">Cover</th>
              <th>Produk</th>
              <th>Kategori</th>
              <th>Tipe</th>
              <th>Harga</th>
              <th>Stok</th>
              <th class="text-right">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredProducts.length === 0">
              <td colspan="7" class="text-center py-8 grey--text">Belum ada data produk yang ditemukan.</td>
            </tr>
            <tr v-for="p in filteredProducts" :key="p.id">
              <td>
                <v-avatar size="44" class="grey lighten-3 rounded-lg" tile>
                  <img v-if="p.cover" :src="p.cover" alt="Cover" style="object-fit: cover;" />
                  <v-icon v-else small color="grey">mdi-image-outline</v-icon>
                </v-avatar>
              </td>
              <td>
                <div class="font-weight-bold">{{ p.title }}</div>
                <div class="caption grey--text">{{ p.sku || '-' }} · {{ p.unit || 'pcs' }}</div>
              </td>
              <td class="font-weight-medium">
                {{ getCategoryName(p) }}
              </td>
              <td>
                <v-chip
                  x-small
                  :color="$vuetify.theme.dark ? (p.product_type === 'resep' ? 'purple darken-4' : 'blue darken-4') : (p.product_type === 'resep' ? 'purple lighten-5' : 'blue lighten-5')"
                  :class="$vuetify.theme.dark ? (p.product_type === 'resep' ? 'purple--text text--lighten-3' : 'blue--text text--lighten-3') : (p.product_type === 'resep' ? 'purple--text' : 'blue--text')"
                  class="font-weight-bold"
                >
                  {{ p.product_type === 'resep' ? 'Resep' : 'Retail' }}
                </v-chip>
              </td>
              <td class="font-weight-bold">Rp {{ Number(p.price || 0).toLocaleString('id-ID') }}</td>
              <td>{{ p.stock !== null && p.stock !== undefined ? p.stock : '—' }}</td>
              <td class="text-right">
                <v-btn v-if="p.product_type !== 'resep'" text x-small color="#0f4c3a" @click="openOpname(p)" class="mr-1">Opname</v-btn>

                <v-btn icon x-small color="blue" class="mr-1" @click="openEditDialog(p)">
                  <v-icon small>mdi-pencil-outline</v-icon>
                </v-btn>

                <v-btn
                  icon
                  x-small
                  color="red"
                  :loading="deletingId === p.id"
                  @click="deleteProduct(p.id)"
                >
                  <v-icon small>mdi-delete-outline</v-icon>
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-simple-table>
      </div>
    </v-card>

    <!-- Dialog Kategori Baru -->
    <v-dialog v-model="dialogCat" max-width="380" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Kategori Produk</h3>
          <v-btn icon small :disabled="isSavingCat" @click="dialogCat = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="mb-3">
          <v-chip
            v-for="cat in categoriesList"
            :key="cat.id"
            small
            class="mr-1 mb-1"
            :color="$vuetify.theme.dark ? '#2d2d2d' : 'grey lighten-3'"
          >
            {{ cat.name }}
          </v-chip>
        </div>

        <v-text-field
          v-model="newCategoryName"
          label="Nama Kategori Baru"
          placeholder="Misal: Kopi Botolan"
          outlined
          dense
          class="rounded-lg mb-2"
        ></v-text-field>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSavingCat"
          :disabled="!newCategoryName.trim()"
          @click="saveCategory"
        >
          Tambah Kategori
        </v-btn>
      </v-card>
    </v-dialog>

    <!-- Dialog Form Tambah / Edit Produk -->
    <v-dialog v-model="dialogAdd" max-width="520" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">{{ isEditMode ? 'Edit Produk' : 'Tambah Produk Baru' }}</h3>
          <v-btn icon small :disabled="isSaving" @click="dialogAdd = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field v-model="form.sku" label="SKU (kosongkan untuk auto-generate)" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model="form.title" label="Nama Produk" outlined dense class="rounded-lg mb-1"></v-text-field>

        <v-select
          v-model="form.category_id"
          :items="categoriesList"
          item-text="name"
          item-value="id"
          label="Kategori"
          outlined
          dense
          class="rounded-lg mb-1"
        ></v-select>

        <!-- Input Cover / Gambar Produk -->
        <div class="caption font-weight-bold mb-1">Gambar Cover Display</div>
        <div class="d-flex align-center mb-3">
          <v-avatar size="56" class="mr-3 grey lighten-3 rounded-lg" tile>
            <img v-if="previewCoverUrl" :src="previewCoverUrl" alt="Preview" style="object-fit: cover;" />
            <v-icon v-else color="grey">mdi-image-outline</v-icon>
          </v-avatar>
          <div class="flex-grow-1">
            <v-file-input
              v-model="coverFile"
              label="Pilih file gambar (PNG/JPG)"
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

        <v-select
          v-model="form.unit"
          :items="unitOptions"
          label="Satuan Produk"
          outlined
          dense
          class="rounded-lg mb-1"
        ></v-select>

        <v-select
          v-model="form.product_type"
          :items="productTypes"
          item-text="text"
          item-value="value"
          label="Tipe Produk"
          outlined
          dense
          class="rounded-lg mb-1"
        ></v-select>

        <v-text-field v-model.number="form.cost_price" label="Harga Modal / HPP (Rp)" type="number" outlined dense class="rounded-lg mb-1"></v-text-field>
        <v-text-field v-model.number="form.price" label="Harga Jual Offline (Rp)" type="number" outlined dense class="rounded-lg mb-1"></v-text-field>

        <v-text-field
          v-if="form.product_type === 'retail'"
          v-model.number="form.stock"
          label="Stok Awal"
          type="number"
          outlined
          dense
          class="rounded-lg mb-3"
        ></v-text-field>

        <!-- Komponen Resep Bahan Baku -->
        <div v-if="form.product_type === 'resep'" class="mb-4 pa-3 rounded-xl" :style="{ backgroundColor: $vuetify.theme.dark ? '#2d2d2d' : '#f5f5f5' }">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="subtitle-2 font-weight-bold">Komponen Bahan Baku Resep</span>
            <v-btn x-small color="#0f4c3a" dark depressed @click="addRecipeRow">
              <v-icon left x-small>mdi-plus</v-icon> Tambah Bahan
            </v-btn>
          </div>

          <div v-if="form.recipes.length === 0" class="caption grey--text text-center py-2">
            Belum ada bahan baku ditambahkan. Klik tombol di atas.
          </div>

          <div v-for="(recipe, index) in form.recipes" :key="index" class="d-flex align-center mb-2">
            <v-select
              v-model="recipe.raw_material_id"
              :items="rawMaterialsList"
              item-text="name"
              item-value="id"
              label="Pilih Bahan Baku"
              outlined
              dense
              hide-details
              class="rounded-lg mr-2"
            ></v-select>

            <v-text-field
              v-model.number="recipe.qty_needed"
              label="Takaran"
              type="number"
              step="0.01"
              outlined
              dense
              hide-details
              class="rounded-lg mr-2"
              style="max-width: 110px;"
            ></v-text-field>

            <v-btn icon x-small color="red" @click="removeRecipeRow(index)">
              <v-icon small>mdi-delete-outline</v-icon>
            </v-btn>
          </div>
        </div>

        <v-btn
          block
          color="#0f4c3a"
          dark
          rounded
          depressed
          :loading="isSaving"
          :disabled="!form.title || !form.category_id || form.price <= 0"
          @click="submitProductForm"
        >
          {{ isEditMode ? 'Simpan Perubahan' : 'Simpan Produk' }}
        </v-btn>
      </v-card>
    </v-dialog>

    <!-- Dialog Opname -->
    <v-dialog v-model="dialogOpname" max-width="360" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="subtitle-1 font-weight-bold">Stok Opname: {{ opnameTarget && opnameTarget.title }}</h3>
          <v-btn icon small :disabled="isSavingOpname" @click="dialogOpname = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <v-text-field
          v-model.number="actualStock"
          label="Stok Fisik Aktual"
          type="number"
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
          Update Stok
        </v-btn>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

export default {
  name: 'ProductsView',
  data: () => ({
    searchQuery: '',
    dialogAdd: false,
    dialogCat: false,
    dialogOpname: false,
    opnameTarget: null,
    actualStock: 0,
    newCategoryName: '',
    isLoading: false,
    isSaving: false,
    isSavingCat: false,
    isSavingOpname: false,
    deletingId: null,
    errorMessage: '',
    categoriesList: [],
    rawMaterialsList: [],
    coverFile: null,
    previewCoverUrl: '',
    removeCover: false,
    unitOptions: ['pcs', 'cup', 'botol', 'porsi', 'box', 'pack', 'bowl', 'plate'],
    productTypes: [
      { text: 'Retail', value: 'retail' },
      { text: 'Resep', value: 'resep' }
    ],
    isEditMode: false,
    editProductId: null,
    form: {
      sku: '',
      title: '',
      category_id: null,
      unit: 'pcs',
      product_type: 'retail',
      cost_price: 0,
      price: 0,
      stock: 10,
      recipes: [],
    },
  }),
  computed: {
    ...mapGetters(['products']),
    filteredProducts() {
      const list = Array.isArray(this.products) ? this.products : [];
      if (!this.searchQuery) return list;
      const q = this.searchQuery.toLowerCase();
      return list.filter(p =>
        (p.title && p.title.toLowerCase().includes(q)) ||
        (p.sku && p.sku.toLowerCase().includes(q))
      );
    }
  },
  async created() {
    await Promise.all([
      this.loadCategories(),
      this.loadRawMaterials(),
      this.loadProducts(),
    ]);
  },
  methods: {
    normalizeId(val) {
      if (val === null || val === undefined || val === '') return null;
      const num = Number(val);
      return Number.isNaN(num) ? val : num;
    },
    extractListPayload(response) {
      if (!response || !response.data) return [];
      if (Array.isArray(response.data.data)) return response.data.data;
      if (Array.isArray(response.data)) return response.data;
      return [];
    },
    getCategoryName(p) {
      if (p.category && typeof p.category === 'object' && p.category.name) {
        return p.category.name;
      }
      if (p.category_name && p.category_name !== 'Umum') {
        return p.category_name;
      }
      const targetId = this.normalizeId(p.category_id);
      if (targetId !== null && this.categoriesList.length > 0) {
        const found = this.categoriesList.find(c => this.normalizeId(c.id) === targetId);
        if (found) return found.name;
      }
      return p.category_name || '-';
    },
    async loadCategories() {
      try {
        const response = await apiClient.get('/categories', {
          params: { _t: Date.now() }
        });
        const items = this.extractListPayload(response);
        this.categoriesList = items.map(c => Object.assign({}, c, {
          id: this.normalizeId(c.id)
        }));
        if (this.categoriesList.length > 0 && !this.form.category_id) {
          this.form.category_id = this.categoriesList[0].id;
        }
      } catch (err) {
        console.error('Gagal memuat kategori:', err);
        this.categoriesList = [];
      }
    },
    async loadRawMaterials() {
      try {
        const response = await apiClient.get('/raw-materials', {
          params: { _t: Date.now() }
        });
        const items = this.extractListPayload(response);
        this.rawMaterialsList = items.map(rm => Object.assign({}, rm, {
          id: this.normalizeId(rm.id)
        }));
      } catch (err) {
        console.error('Gagal memuat bahan baku:', err);
        this.rawMaterialsList = [];
      }
    },
    async loadProducts() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data produk dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    openAddDialog() {
      this.isEditMode = false;
      this.editProductId = null;
      this.coverFile = null;
      this.previewCoverUrl = '';
      this.removeCover = false;
      const defaultCategoryId = this.categoriesList.length > 0
        ? this.normalizeId(this.categoriesList[0].id)
        : null;
      this.form = {
        sku: '',
        title: '',
        category_id: defaultCategoryId,
        unit: 'pcs',
        product_type: 'retail',
        cost_price: 0,
        price: 0,
        stock: 10,
        recipes: [],
      };
      this.dialogAdd = true;
    },
    async openEditDialog(p) {
      if (this.categoriesList.length === 0) {
        await this.loadCategories();
      }
      if (this.rawMaterialsList.length === 0) {
        await this.loadRawMaterials();
      }

      this.isEditMode = true;
      this.editProductId = p.id;
      this.coverFile = null;
      this.previewCoverUrl = p.cover || '';
      this.removeCover = false;

      const resolvedCategoryId = p.category_id !== null && p.category_id !== undefined
        ? this.normalizeId(p.category_id)
        : (p.category && typeof p.category === 'object' && p.category.id !== undefined
            ? this.normalizeId(p.category.id)
            : null);

      const mappedRecipes = Array.isArray(p.recipes)
        ? p.recipes.map(r => ({
            raw_material_id: r.raw_material_id !== null && r.raw_material_id !== undefined
              ? this.normalizeId(r.raw_material_id)
              : (r.raw_material && r.raw_material.id !== undefined ? this.normalizeId(r.raw_material.id) : null),
            qty_needed: Number(r.qty_needed || 0)
          }))
        : [];

      this.form = {
        sku: p.sku || '',
        title: p.title || '',
        category_id: resolvedCategoryId,
        unit: p.unit || 'pcs',
        product_type: p.product_type || 'retail',
        cost_price: Number(p.cost_price || 0),
        price: Number(p.price || 0),
        stock: Number(p.stock || 0),
        recipes: mappedRecipes
      };
      this.dialogAdd = true;
    },
    previewCoverImage(file) {
      if (!file) return;
      this.removeCover = false;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.previewCoverUrl = e.target.result;
      };
      reader.readAsDataURL(file);
    },
    clearCoverImage() {
      this.coverFile = null;
      this.previewCoverUrl = '';
      this.removeCover = true;
    },
    addRecipeRow() {
      this.form.recipes.push({ raw_material_id: null, qty_needed: 1 });
    },
    removeRecipeRow(index) {
      this.form.recipes.splice(index, 1);
    },
    async saveCategory() {
      this.isSavingCat = true;
      this.errorMessage = '';
      try {
        await apiClient.post('/categories', { name: this.newCategoryName.trim() });
        this.newCategoryName = '';
        this.dialogCat = false;
        await this.loadCategories();
      } catch (err) {
        this.errorMessage =
          (err && err.response && err.response.data && err.response.data.message) ||
          'Gagal menambahkan kategori baru.';
      } finally {
        this.isSavingCat = false;
      }
    },
    async submitProductForm() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const formData = new FormData();
        formData.append('sku', this.form.sku ? this.form.sku : '');
        formData.append('title', this.form.title);
        formData.append('category_id', this.form.category_id);
        formData.append('unit', this.form.unit);
        formData.append('product_type', this.form.product_type);
        formData.append('cost_price', Number(this.form.cost_price || 0));
        formData.append('price', Number(this.form.price));
        formData.append('stock', this.form.product_type === 'resep' ? 0 : Number(this.form.stock || 0));

        if (this.coverFile) {
          formData.append('cover', this.coverFile);
        } else if (this.isEditMode && this.removeCover) {
          formData.append('remove_cover', 1);
        }

        if (this.form.product_type === 'resep' && this.form.recipes.length > 0) {
          formData.append('recipes', JSON.stringify(this.form.recipes));
        }

        const config = {
          headers: { 'Content-Type': 'multipart/form-data' }
        };

        if (this.isEditMode) {
          await apiClient.post(`/products/${this.editProductId}?_method=PUT`, formData, config);
        } else {
          await apiClient.post('/products', formData, config);
        }

        await this.$store.dispatch('fetchPosData');
        this.dialogAdd = false;
      } catch (err) {
        if (err && err.response && err.response.data && err.response.data.errors) {
          const errs = err.response.data.errors;
          this.errorMessage = Object.values(errs).flat().join(', ');
        } else {
          this.errorMessage = (err && err.response && err.response.data && err.response.data.message) || 'Gagal menyimpan produk.';
        }
      } finally {
        this.isSaving = false;
      }
    },
    async deleteProduct(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await apiClient.delete(`/products/${id}`);
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        this.errorMessage = 'Gagal menghapus produk dari database.';
      } finally {
        this.deletingId = null;
      }
    },
    openOpname(p) {
      this.opnameTarget = p;
      this.actualStock = p.stock;
      this.dialogOpname = true;
    },
    async saveOpname() {
      this.isSavingOpname = true;
      this.errorMessage = '';
      try {
        await apiClient.post(`/products/${this.opnameTarget.id}/opname`, {
          actual_stock: this.actualStock,
        });
        await this.$store.dispatch('fetchPosData');
        this.dialogOpname = false;
      } catch (err) {
        this.errorMessage = 'Gagal memperbarui stok opname ke database.';
      } finally {
        this.isSavingOpname = false;
      }
    },
  },
};
</script>