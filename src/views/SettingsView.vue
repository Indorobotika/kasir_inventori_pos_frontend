<template>
  <v-container fluid class="pa-5">
    <h1 class="headline font-weight-bold">Pengaturan</h1>
    <div class="caption grey--text text--darken-1 mb-4">Identitas toko, pajak, dan format struk thermal.</div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4" max-width="760">
      {{ errorMessage }}
    </v-alert>

    <v-card flat outlined class="pa-6 rounded-xl white" max-width="760">
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

        <div class="caption font-weight-bold mb-1">URL logo</div>
        <v-text-field v-model="form.logo_path_url" placeholder="https://..." outlined dense class="rounded-lg"></v-text-field>

        <div class="caption font-weight-bold mb-1">Lebar kertas struk</div>
        <v-select v-model="form.receipt_width" :items="['44 mm', '58 mm', '80 mm']" outlined dense class="rounded-lg"></v-select>

        <div class="caption font-weight-bold mb-1">Catatan kaki struk</div>
        <v-text-field v-model="form.receipt_footer" outlined dense class="rounded-lg"></v-text-field>

        <div class="d-flex align-center mt-2">
          <v-btn
            color="#0f4c3a"
            dark
            rounded
            depressed
            large
            class="px-6"
            :loading="isSaving"
            @click="save"
          >
            Simpan Pengaturan
          </v-btn>
          <span v-if="saved" class="ml-3 caption green--text font-weight-bold">✓ Pengaturan tersimpan</span>
        </div>
      </template>
    </v-card>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'SettingsView',
  data() {
    return {
      form: { ...this.$store.getters.setting },
      isLoading: false,
      isSaving: false,
      saved: false,
      errorMessage: '',
    };
  },
  computed: {
    ...mapGetters(['setting']),
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
    async save() {
      this.isSaving = true;
      this.saved = false;
      this.errorMessage = '';
      try {
        const payload = {
          ...this.form,
          tax: Number(this.form.tax || 0),
        };
        await this.$store.dispatch('saveSettings', payload);
        this.saved = true;
        setTimeout(() => {
          this.saved = false;
        }, 2500);
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menyimpan pengaturan ke database.';
      } finally {
        this.isSaving = false;
      }
    },
  },
};
</script>