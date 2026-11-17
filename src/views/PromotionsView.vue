<template>
  <v-container fluid class="pa-5">
    <div class="d-flex justify-space-between align-center mb-4">
      <div>
        <h1 class="headline font-weight-bold">Promo</h1>
        <div class="caption grey--text text--darken-1">Diskon otomatis diterapkan di kasir sesuai minimal belanja.</div>
      </div>
      <v-btn color="#0f4c3a" dark rounded depressed @click="dialog = true">
        <v-icon left small>mdi-plus</v-icon> Promo Baru
      </v-btn>
    </div>

    <v-alert v-if="errorMessage" type="error" dense outlined class="rounded-lg mb-4">
      {{ errorMessage }}
    </v-alert>

    <div v-if="isLoading" class="text-center py-10">
      <v-progress-circular indeterminate color="#0f4c3a"></v-progress-circular>
      <div class="caption grey--text mt-2">Memuat daftar promo...</div>
    </div>

    <v-card v-else-if="promotions.length === 0" flat outlined class="pa-8 rounded-xl white text-center grey--text">
      Belum ada promo aktif di database. Klik "Promo Baru" untuk menambahkan.
    </v-card>

    <v-row v-else>
      <v-col v-for="promo in promotions" :key="promo.id" cols="12" md="6">
        <v-card flat outlined class="pa-5 rounded-xl white">
          <div class="d-flex justify-space-between align-start">
            <div>
              <div class="subtitle-1 font-weight-bold">{{ promo.title }}</div>
              <div class="caption grey--text">
                Min. belanja Rp {{ Number(promo.required || 0).toLocaleString('id-ID') }}
              </div>
            </div>
            <v-chip
              x-small
              :color="Number(promo.is_active) === 1 ? 'green lighten-4' : 'grey lighten-3'"
              :class="Number(promo.is_active) === 1 ? 'green--text text--darken-3' : 'grey--text'"
              class="font-weight-bold"
            >
              {{ Number(promo.is_active) === 1 ? 'Aktif' : 'Nonaktif' }}
            </v-chip>
          </div>
          <div class="headline font-weight-bold teal--text text--darken-4 mt-4">
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

    <v-dialog v-model="dialog" max-width="420" persistent>
      <v-card class="rounded-xl pa-5">
        <div class="d-flex justify-space-between align-center mb-3">
          <h3 class="headline font-weight-bold">Tambah Promo Baru</h3>
          <v-btn icon small :disabled="isSaving" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
        </div>

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
          outlined
          dense
          class="rounded-lg"
        ></v-text-field>
        <v-text-field
          v-model.number="form.result"
          :label="form.typ_promotion_id === 2 ? 'Nilai Diskon (%)' : 'Nilai Diskon (Rp)'"
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
          :disabled="!form.title.trim() || form.result <= 0"
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

export default {
  name: 'PromotionsView',
  data: () => ({
    dialog: false,
    isLoading: false,
    isSaving: false,
    deletingId: null,
    errorMessage: '',
    form: { title: '', typ_promotion_id: 2, required: 50000, result: 10, is_active: 1 },
  }),
  computed: {
    ...mapGetters(['promotions']),
  },
  async created() {
    await this.loadPromos();
  },
  methods: {
    async loadPromos() {
      this.isLoading = true;
      this.errorMessage = '';
      try {
        await this.$store.dispatch('fetchPosData');
      } catch (err) {
        if (err.response && err.response.status === 401) {
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
        this.form = { title: '', typ_promotion_id: 2, required: 50000, result: 10, is_active: 1 };
      } catch (err) {
        this.errorMessage =
          (err.response && err.response.data && err.response.data.message) ||
          'Gagal menyimpan promo baru ke database.';
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