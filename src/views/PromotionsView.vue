<template>
  <v-container fluid class="pa-3 pa-md-5">
    <!-- Header -->
    <div class="d-flex flex-wrap justify-space-between align-center mb-4">
      <div class="mb-2 mb-md-0">
        <h1 class="headline font-weight-bold">Promo</h1>
        <div class="caption grey--text text--darken-1">Diskon otomatis diterapkan di kasir sesuai minimal belanja.</div>
      </div>
      <v-btn color="#0f4c3a" dark rounded depressed @click="openAddDialog">
        <v-icon left small>mdi-plus</v-icon> Promo Baru
      </v-btn>
    </div>

    <v-alert v-if="errorMessage && !dialog" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <div v-if="isLoading" class="text-center py-10">
      <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
      <div class="caption grey--text mt-2">Memuat daftar promo...</div>
    </div>

    <v-card
      v-else-if="promotions.length === 0"
      flat
      outlined
      class="pa-8 rounded-xl text-center grey--text"
      :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'"
    >
      Belum ada promo aktif di database. Klik "Promo Baru" untuk menambahkan.
    </v-card>

    <v-row v-else>
      <v-col v-for="promo in promotions" :key="promo.id" cols="12" md="6" class="mb-3">
        <v-card flat outlined class="pa-4 pa-md-5 rounded-xl h-100" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
          <div class="d-flex justify-space-between align-start">
            <div>
              <div class="subtitle-1 font-weight-bold">{{ promo.title }}</div>
              <div class="caption grey--text">
                Min. belanja Rp {{ Number(promo.required || 0).toLocaleString('id-ID') }}
              </div>
            </div>
            <v-chip
              x-small
              :color="$vuetify.theme.dark ? (Number(promo.is_active) === 1 ? 'green darken-4' : 'grey darken-3') : (Number(promo.is_active) === 1 ? 'green lighten-4' : 'grey lighten-3')"
              :class="$vuetify.theme.dark ? (Number(promo.is_active) === 1 ? 'green--text text--lighten-3' : 'grey--text text--lighten-1') : (Number(promo.is_active) === 1 ? 'green--text text--darken-3' : 'grey--text')"
              class="font-weight-bold"
            >
              {{ Number(promo.is_active) === 1 ? 'Aktif' : 'Nonaktif' }}
            </v-chip>
          </div>
          <div class="headline font-weight-bold teal--text text--lighten-2 mt-4">
            {{ Number(promo.typ_promotion_id) === 2 ? `${Number(promo.result || 0)}%` : `Rp ${Number(promo.result || 0).toLocaleString('id-ID')}` }}
          </div>
          <div class="text-right mt-2">
            <v-btn
              icon
              x-small
              color="red"
              :loading="deletingId === promo.id"
              @click="deletePromo(promo.id)"
            >
              <v-icon small>mdi-delete-outline</v-icon>
            </v-btn>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Dialog Tambah Promo -->
    <v-dialog v-model="dialog" max-width="420" persistent>
      <v-card class="rounded-xl pa-5" :color="$vuetify.theme.dark ? '#1e1e1e' : 'white'">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Tambah Promo Baru</h3>
          <v-btn icon small :disabled="isSaving" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

        <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-3">
          {{ errorMessage }}
        </v-alert>

        <v-text-field v-model="form.title" label="Judul Promo" outlined dense class="rounded-lg"></v-text-field>
        <v-select
          v-model="form.typ_promotion_id"
          :items="[{ text: 'Persentase (%)', value: 2 }, { text: 'Nominal (Rp)', value: 1 }]"
          item-text="text"
          item-value="value"
          label="Jenis Diskon"
          outlined
          dense
          class="rounded-lg"
        ></v-select>
        <v-text-field
          v-model.number="form.required"
          label="Minimal Belanja (Rp)"
          type="number"
          min="0"
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model.number="form.result"
          :label="Number(form.typ_promotion_id) === 2 ? 'Nilai Diskon (%)' : 'Nilai Diskon (Rp)'"
          type="number"
          min="0"
          :max="Number(form.typ_promotion_id) === 2 ? 100 : undefined"
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
          :disabled="!isFormValid"
          @click="savePromo"
        >
          Simpan Promo
        </v-btn>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
import { mapGetters } from 'vuex';
import apiClient from '@/services/api';

function defaultForm() {
  return {
    title: '',
    typ_promotion_id: 2,
    required: 50000,
    result: 10,
    is_active: 1,
  };
}

export default {
  name: 'PromotionsView',
  data: () => ({
    dialog: false,
    isLoading: false,
    isSaving: false,
    deletingId: null,
    errorMessage: '',
    form: defaultForm(),
  }),
  computed: {
    ...mapGetters(['promotions']),
    isFormValid() {
      const titleOk = Boolean(this.form.title && this.form.title.trim());
      const reqVal = Number(this.form.required);
      const resVal = Number(this.form.result);
      const reqOk = !Number.isNaN(reqVal) && reqVal >= 0;
      const resOk = !Number.isNaN(resVal) && resVal > 0 && (
        Number(this.form.typ_promotion_id) !== 2 || resVal <= 100
      );
      return titleOk && reqOk && resOk;
    },
  },
  async created() {
    await this.loadPromos();
  },
  methods: {
    openAddDialog() {
      this.errorMessage = '';
      this.form = defaultForm();
      this.dialog = true;
    },
    async loadPromos() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err && err.response && err.response.status === 401) {
          this.$store.commit('SET_AUTH', { token: null, user: null });
        } else {
          this.errorMessage = 'Gagal memuat data promo dari server.';
        }
      } finally {
        this.isLoading = false;
      }
    },
    async savePromo() {
      this.isSaving = true;
      this.errorMessage = '';
      try {
        const payload = {
          title: this.form.title.trim(),
          typ_promotion_id: Number(this.form.typ_promotion_id),
          required: Number(this.form.required || 0),
          result: Number(this.form.result || 0),
          is_active: 1,
        };
        await apiClient.post('/promotions', payload);
        await this.$store.dispatch('fetchPosData');
        this.dialog = false;
        this.form = defaultForm();
      } catch (err) {
        if (err && err.response && err.response.data) {
          const errors = err.response.data.errors;
          if (errors) {
            this.errorMessage = Object.values(errors).flat().join(', ');
          } else {
            this.errorMessage = err.response.data.message || 'Gagal menyimpan promo baru ke database.';
          }
        } else {
          this.errorMessage = 'Gagal terhubung ke server.';
        }
      } finally {
        this.isSaving = false;
      }
    },
    async deletePromo(id) {
      this.deletingId = id;
      this.errorMessage = '';
      try {
        await apiClient.delete(`/promotions/${id}`);
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        this.errorMessage = 'Gagal menghapus promo dari database.';
      } finally {
        this.deletingId = null;
      }
    },
  },
};
</script>