<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Produk</h1>
        <div class="caption grey--text text--darken-1">Produk retail dan produksi sendiri, lengkap dengan resep bahan baku.</div>
      </div>
      <div>
        <v-btn outlined rounded class="mr-2 white" @click="dialogCat = true">Kategori</v-btn>
        <v-btn color="#0f4c3a" dark rounded depressed @click="dialogAdd = true">
          <v-icon left small>mdi-plus</v-icon> Produk Baru
        </v-btn>
      </div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-card flat outlined class="rounded-xl white">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat daftar produk...</div>
      </div>

      <v-simple-table v-else>
        <thead>
          <tr>
            <th>Produk</th>
            <th>Kategori</th>
            <th>Tipe</th>
            <th>Harga</th>
            <th>Stok</th>
            <th class="text-right">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="products.length === 0">
            <td colspan="6" class="text-center py-8 grey--text">Belum ada data produk di database.</td>
          </tr>
          <tr v-for="p in products" :key="p.id">
            <td>
              <div class="font-weight-bold">{{ p.title }}</div>
              <div class="caption grey--text">{{ p.sku || '-' }} · {{ p.unit || 'pcs' }}</div>
            </td>
            <td>{{ p.category }}</td>
            <td>
              <v-chip
                x-small
                :color="p.type === 'Resep' ? 'purple lighten-5' : 'blue lighten-5'"
                :class="p.type === 'Resep' ? 'purple--text' : 'blue--text'"
                class="font-weight-bold"
              >
                {{ p.type || 'Retail' }}
              </v-chip>
            </td>
            <td class="font-weight-bold">Rp {{ Number(p.price || 0).toLocaleString('id-ID') }}</td>
            <td>{{ p.stock !== null && p.stock !== undefined ? p.stock : '—' }}</td>
            <td class="text-right">
              <v-btn v-if="p.type !== 'Resep'" text x-small @click="openOpname(p)">Opname</v-btn>
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
    </v-card>

    <!-- Dialog Tambah Kategori Baru -->
    <v-dialog v-model="dialogCat" max-width="380" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Kategori Produk</h3>
          <v-btn icon small :disabled="isSavingCat" @click="dialogCat = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <div class="mb-3">
          <v-chip
            v-for="cat in availableCategories"
            :key="cat"
            small
            class="mr-1 mb-1"
            color="grey lighten-3"
          >
            {{ cat }}
          </v-chip>
        </div>

        <v-text-field
          v-model="newCategoryName"
          label="Nama Kategori Baru"
          placeholder="Misal: Kopi Botolan"
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
          :loading="isSavingCat"
          :disabled="!newCategoryName.trim()"
          @click="saveCategory"
        >
          Tambah Kategori
        </v-btn>
      </v-card>
    </v-dialog>

    <!-- Dialog Tambah Produk -->
    <v-dialog v-model="dialogAdd" max-width="450" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Tambah Produk Baru</h3>
          <v-btn icon small :disabled="isSaving" @click="dialogAdd = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-text-field v-model="form.sku" label="SKU (misal: MNM-05)" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model="form.title" label="Nama Produk" outlined dense class="rounded-lg"></v-text-field>
        <v-select
          v-model="form.category"
          :items="availableCategories"
          label="Kategori"
          outlined
          dense
          class="rounded-lg"
        ></v-select>
        <v-text-field v-model="form.unit" label="Satuan (misal: pcs, cup, botol)" outlined dense class="rounded-lg"></v-text-field>
        <v-select
          v-model="form.type"
          :items="['Retail', 'Resep']"
          label="Tipe Produk"
          outlined
          dense
          class="rounded-lg"
        ></v-select>
        <v-text-field v-model.number="form.cost_price" label="Harga Modal / HPP (Rp)" type="number" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field v-model.number="form.price" label="Harga Jual Offline (Rp)" type="number" outlined dense class="rounded-lg"></v-text-field>
        <v-text-field
          v-if="form.type === 'Retail'"
          v-model.number="form.stock"
          label="Stok Awal"
          type="number"
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
          :disabled="!form.title || form.price <= 0"
          @click="saveProduct"
        >
          Simpan Produk
        </v-btn>
      </v-card>
    </v-dialog>

    <!-- Dialog Opname -->
    <v-dialog v-model="dialogOpname" max-width="360" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-2">
          <h3 class="subtitle-1 font-weight-bold">Stok Opname: {{ opnameTarget && opnameTarget.title }}</h3>
          <v-btn icon small :disabled="isSavingOpname" @click="dialogOpname = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <v-text-field
          v-model.number="actualStock"
          label="Stok Fisik Aktual"
          type="number"
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
    form: {
      sku: '',
      title: '',
      category: '',
      unit: 'pcs',
      type: 'Retail',
      cost_price: 0,
      price: 0,
      stock: 10,
    },
  }),
  computed: {
    ...mapGetters(['products', 'categories']),
    availableCategories() {
      const list = this.categories.filter((c) => c !== 'Semua');
      return list.length > 0 ? list : ['Minuman', 'Makanan', 'Snack', 'Produk Rumahan'];
    },
  },
  async created() {
    await this.loadProducts();
    if (!this.form.category && this.availableCategories.length > 0) {
      this.form.category = this.availableCategories[0];
    }
  },
  methods: {
    async loadProducts() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data produk dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    async saveCategory() {
      this.isSavingCat = true;
      this.errorMessage = '';
      try {
        await apiClient.post('/categories', { name: this.newCategoryName.trim() });
        await this.$store.dispatch('fetchPosData');
        this.newCategoryName = '';
        this.dialogCat = false;
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menambahkan kategori baru.';
      } finally {
        this.isSavingCat = false;
      }
    },
    async saveProduct() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const payload = {
          ...this.form,
          name: this.form.title,
          stock: this.form.type === 'Resep' ? null : Number(this.form.stock),
          price: Number(this.form.price),
          cost_price: Number(this.form.cost_price || 0),
        };
        await this.$store.dispatch('createProduct', payload);
        await this.$store.dispatch('fetchPosData');
        this.dialogAdd = false;
        this.form = {
          sku: '',
          title: '',
          category: this.availableCategories[0] || 'Minuman',
          unit: 'pcs',
          type: 'Retail',
          cost_price: 0,
          price: 0,
          stock: 10,
        };
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menyimpan produk baru ke database.';
      } finally {
        this.isSaving = false;
      }
    },
    async deleteProduct(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('removeProduct', id);
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
        await this.$store.dispatch('submitStockOpname', {
          type: 'product',
          id: this.opnameTarget.id,
          actualStock: this.actualStock,
        });
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