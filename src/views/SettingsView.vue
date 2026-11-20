<template>
  <v-container fluid class="pa-3 pa-md-5">
    <div class="mb-4">
      <h1 class="headline font-weight-bold">Pengaturan</h1>
      <div class="caption grey--text text--darken-1">Identitas toko, pajak, logo aplikasi, QRIS pembayaran, dan format struk thermal.</div>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <v-card flat outlined class="pa-4 pa-md-6 rounded-xl" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
      <div v-if="isLoading" class="text-center py-8">
        <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
        <div class="caption grey--text mt-2">Memuat pengaturan toko...</div>
      </div>

      <template v-else>
        <div class="caption font-weight-bold mb-1">Nama toko</div>
        <v-text-field v-model="form.store_name" outlined dense class="rounded-lg"></v-text-field>

        <div class="caption font-weight-bold mb-1">Alamat toko</div>
        <v-text-field v-model="form.location_store" outlined dense class="rounded-lg"></v-text-field>

        <v-row>
          <v-col cols="12" md="6">
            <div class="caption font-weight-bold mb-1">Kontak</div>
            <v-text-field v-model="form.contact" outlined dense class="rounded-lg"></v-text-field>
          </v-col>
          <v-col cols="12" md="6">
            <div class="caption font-weight-bold mb-1">Pajak (%)</div>
            <v-text-field
              v-model.number="form.tax"
              type="number"
              step="0.01"
              min="0"
              max="100"
              outlined
              dense
              class="rounded-lg"
            ></v-text-field>
          </v-col>
        </v-row>

        <!-- Bagian Unggah Logo Aplikasi -->
        <div class="caption font-weight-bold mb-1">Logo Aplikasi Toko</div>
        <div class="d-flex flex-wrap align-center mb-3">
          <v-avatar v-if="displayLogoUrl" size="64" class="mr-4 mb-2 grey lighten-3 rounded-lg" tile>
            <img :src="displayLogoUrl" alt="Logo Toko" style="object-fit: cover;" />
          </v-avatar>
          <div class="flex-grow-1" style="min-width: 220px;">
            <v-file-input
              v-model="logoFile"
              label="Pilih file logo baru (PNG/JPG)"
              accept="image/png, image/jpeg, image/jpg"
              outlined
              dense
              hide-details
              class="rounded-lg"
              prepend-icon="mdi-camera"
              @change="previewLogo"
            ></v-file-input>
          </div>
          <v-btn
            v-if="displayLogoUrl"
            text
            small
            color="red darken-1"
            class="ml-sm-2 mt-2 mt-sm-0"
            @click="markRemoveLogo"
          >
            Hapus Logo
          </v-btn>
        </div>

        <!-- Bagian Unggah Gambar QRIS -->
        <div class="caption font-weight-bold mb-1">Gambar QRIS Pembayaran</div>
        <div class="d-flex flex-wrap align-center mb-3">
          <v-avatar v-if="displayQrisUrl" size="72" class="mr-4 mb-2 grey lighten-3 rounded-lg" tile>
            <img :src="displayQrisUrl" alt="QRIS" style="object-fit: contain;" />
          </v-avatar>
          <div class="flex-grow-1" style="min-width: 220px;">
            <v-file-input
              v-model="qrisFile"
              label="Pilih file QRIS baru (PNG/JPG)"
              accept="image/png, image/jpeg, image/jpg"
              outlined
              dense
              hide-details
              class="rounded-lg"
              prepend-icon="mdi-qrcode-scan"
              @change="previewQris"
            ></v-file-input>
          </div>
          <v-btn
            v-if="displayQrisUrl"
            text
            small
            color="red darken-1"
            class="ml-sm-2 mt-2 mt-sm-0"
            @click="markRemoveQris"
          >
            Hapus QRIS
          </v-btn>
        </div>

        <div class="caption font-weight-bold mb-1">Lebar kertas struk</div>
        <v-select
          v-model="form.receipt_width"
          :items="['44 mm', '58 mm', '80 mm']"
          outlined
          dense
          class="rounded-lg"
        ></v-select>

        <div class="caption font-weight-bold mb-1">Catatan kaki struk</div>
        <v-text-field v-model="form.receipt_footer" outlined dense class="rounded-lg"></v-text-field>

        <div class="d-flex flex-wrap align-center mt-3">
          <v-btn
            color="#0f4c3a"
            dark
            rounded
            depressed
            large
            class="px-6 mb-2 mr-3"
            :loading="isSaving"
            @click="save"
          >
            Simpan Pengaturan
          </v-btn>
          <span v-if="saved" class="caption green--text font-weight-bold mb-2">✓ Pengaturan tersimpan</span>
        </div>
      </template>
    </v-card>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

function defaultForm() {
  return {
    store_name: '',
    location_store: '',
    contact: '',
    tax: 11,
    logo_path_url: '',
    qris_path_url: '',
    receipt_width: '58 mm',
    receipt_footer: '',
  };
}

export default {
  name: 'SettingsView',
  data() {
    return {
      form: defaultForm(),
      logoPreviewUrl: '',
      qrisPreviewUrl: '',
      removeLogoFlag: false,
      removeQrisFlag: false,
      logoFile: null,
      qrisFile: null,
      isLoading: false,
      isSaving: false,
      saved: false,
      errorMessage: '',
    };
  },
  computed: {
    ...mapGetters(['setting']),
    displayLogoUrl() {
      if (this.logoPreviewUrl) return this.logoPreviewUrl;
      if (this.removeLogoFlag) return '';
      return this.form.logo_path_url || '';
    },
    displayQrisUrl() {
      if (this.qrisPreviewUrl) return this.qrisPreviewUrl;
      if (this.removeQrisFlag) return '';
      return this.form.qris_path_url || '';
    },
  },
  watch: {
    setting: {
      immediate: true,
      handler(newVal) {
        if (newVal && typeof newVal === 'object') {
          this.syncFormFromData(newVal);
        }
      },
    },
  },
  async created() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await this.$store.dispatch('fetchPosData');
      if (this.setting && typeof this.setting === 'object') {
        this.syncFormFromData(this.setting);
      }
    } catch (err) {
      if (err.response && err.response.status === 401) {
        this.$store.commit('SET_AUTH', { token: null, user: null });
      } else {
        this.errorMessage = 'Gagal memuat pengaturan toko dari server.';
      }
    } finally {
      this.isLoading = false;
    }
  },
  methods: {
    syncFormFromData(data) {
      const base = defaultForm();
      const parsedTax = data.tax !== undefined && data.tax !== null && data.tax !== ''
        ? Number(data.tax)
        : base.tax;

      this.form = {
        ...base,
        ...data,
        tax: Number.isNaN(parsedTax) ? base.tax : parsedTax,
        logo_path_url: data.logo_path_url || '',
        qris_path_url: data.qris_path_url || '',
        receipt_width: data.receipt_width || base.receipt_width,
        receipt_footer: data.receipt_footer !== undefined && data.receipt_footer !== null
          ? data.receipt_footer
          : base.receipt_footer,
      };
      this.logoPreviewUrl = '';
      this.qrisPreviewUrl = '';
      this.removeLogoFlag = false;
      this.removeQrisFlag = false;
    },
    previewLogo(file) {
      this.logoPreviewUrl = '';
      if (!file) return;

      this.removeLogoFlag = false;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.logoPreviewUrl = e.target.result || '';
      };
      reader.readAsDataURL(file);
    },
    previewQris(file) {
      this.qrisPreviewUrl = '';
      if (!file) return;

      this.removeQrisFlag = false;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.qrisPreviewUrl = e.target.result || '';
      };
      reader.readAsDataURL(file);
    },
    markRemoveLogo() {
      this.logoFile = null;
      this.logoPreviewUrl = '';
      this.removeLogoFlag = true;
    },
    markRemoveQris() {
      this.qrisFile = null;
      this.qrisPreviewUrl = '';
      this.removeQrisFlag = true;
    },
    async save() {
      this.isSaving = true;
      this.saved = false;
      this.errorMessage = '';

      try {
        const taxVal = Number(this.form.tax);
        const safeTax = Number.isNaN(taxVal) ? 0 : Math.min(100, Math.max(0, taxVal));

        const formData = new FormData();
        formData.append('store_name', (this.form.store_name || '').trim());
        formData.append('location_store', this.form.location_store || '');
        formData.append('contact', this.form.contact || '');
        formData.append('tax', String(safeTax));
        formData.append('receipt_width', this.form.receipt_width || '58 mm');
        formData.append('receipt_footer', this.form.receipt_footer || '');

        if (this.logoFile) {
          formData.append('logo', this.logoFile);
        } else if (this.removeLogoFlag) {
          formData.append('remove_logo', '1');
        }

        if (this.qrisFile) {
          formData.append('qris', this.qrisFile);
        } else if (this.removeQrisFlag) {
          formData.append('remove_qris', '1');
        }

        const res = await apiClient.post('/settings', formData);
        const updated = (res.data && res.data.data) ? res.data.data : (res.data || {});

        this.logoFile = null;
        this.qrisFile = null;
        this.syncFormFromData(updated);

        this.$store.commit('UPDATE_SETTING', updated);

        this.saved = true;
        setTimeout(() => {
          this.saved = false;
        }, 2500);
      } catch (err) {
        if (err.response && err.response.data) {
          const errors = err.response.data.errors;
          if (errors) {
            this.errorMessage = Object.values(errors).flat().join(', ');
          } else {
            this.errorMessage = err.response.data.message || 'Gagal menyimpan pengaturan ke database.';
          }
        } else {
          this.errorMessage = 'Gagal terhubung ke server.';
        }
      } finally {
        this.isSaving = false;
      }
    },
  },
};
</script>