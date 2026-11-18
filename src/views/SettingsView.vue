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
            <v-text-field v-model.number="form.tax" type="number" outlined dense class="rounded-lg"></v-text-field>
          </v-col>
        </v-row>

        <!-- Bagian Unggah Logo Aplikasi -->
        <div class="caption font-weight-bold mb-1">Logo Aplikasi Toko</div>
        <div class="d-flex flex-wrap align-center mb-3">
          <v-avatar v-if="form.logo_path_url" size="64" class="mr-4 mb-2 grey lighten-3 rounded-lg" tile>
            <img :src="form.logo_path_url" alt="Logo Toko" style="object-fit: cover;" />
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
        </div>

        <!-- Bagian Unggah Gambar QRIS -->
        <div class="caption font-weight-bold mb-1">Gambar QRIS Pembayaran</div>
        <div class="d-flex flex-wrap align-center mb-3">
          <v-avatar v-if="form.qris_path_url" size="72" class="mr-4 mb-2 grey lighten-3 rounded-lg" tile>
            <img :src="form.qris_path_url" alt="QRIS" style="object-fit: contain;" />
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
        </div>

        <div class="caption font-weight-bold mb-1">Lebar kertas struk</div>
        <v-select v-model="form.receipt_width" :items="['44 mm', '58 mm', '80 mm']" outlined dense class="rounded-lg"></v-select>

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

export default {
  name: 'SettingsView',
  data() {
    return {
      form: {
        store_name: '',
        location_store: '',
        contact: '',
        tax: 0,
        logo_path_url: '',
        qris_path_url: '',
        receipt_width: '58 mm',
        receipt_footer: '',
      },
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
  },
  watch: {
    setting: {
      immediate: true,
      handler(newVal) {
        if (newVal) {
          this.form = { ...newVal };
        }
      },
    },
  },
  async created() {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      await this.$store.dispatch('fetchPosData');
      this.form = { ...this.setting };
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
    previewLogo(file) {
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.form.logo_path_url = e.target.result;
      };
      reader.readAsDataURL(file);
    },
    previewQris(file) {
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.form.qris_path_url = e.target.result;
      };
      reader.readAsDataURL(file);
    },
    async save() {
      this.isSaving = true;
      this.saved = false;
      this.errorMessage = '';
      try {
        const formData = new FormData();
        formData.append('store_name', this.form.store_name || '');
        formData.append('location_store', this.form.location_store || '');
        formData.append('contact', this.form.contact || '');
        formData.append('tax', Number(this.form.tax || 0));
        formData.append('receipt_width', this.form.receipt_width || '58 mm');
        formData.append('receipt_footer', this.form.receipt_footer || '');

        if (this.logoFile) {
          formData.append('logo', this.logoFile);
        }
        if (this.qrisFile) {
          formData.append('qris', this.qrisFile);
        }

        const res = await apiClient.post('/settings', formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });

        const updated = res.data.data || res.data;
        this.form = { ...updated };
        this.logoFile = null;
        this.qrisFile = null;

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