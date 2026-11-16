<template>
  <v-app style="background-color: #f8f7f4;">
    <v-navigation-drawer v-if="isAuthenticated" app permanent width="235" color="#0f4c3a" dark>
      <div class="pa-4 d-flex align-center">
        <v-avatar color="#f5820d" rounded size="40" class="mr-3">
          <v-icon color="black">mdi-coffee</v-icon>
        </v-avatar>
        <div>
          <div class="font-weight-bold subtitle-2 white--text">Kasir & Inventori</div>
          <div class="caption grey--text text--lighten-2">Point of Sale</div>
        </div>
      </div>

      <v-list nav dense class="px-3 mt-1">
        <v-list-item
          v-for="menu in menus"
          :key="menu.to"
          :to="menu.to"
          exact
          active-class="active-nav-item"
          class="rounded-lg mb-1"
        >
          <v-list-item-icon class="mr-3">
            <v-icon small>{{ menu.icon }}</v-icon>
          </v-list-item-icon>
          <v-list-item-content>
            <v-list-item-title class="body-2 font-weight-medium">{{ menu.title }}</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
      </v-list>

      <template v-slot:append>
        <div class="pa-3 border-top-teal d-flex align-center justify-space-between">
          <div class="d-flex align-center">
            <v-avatar color="#236854" size="34" class="mr-2">
              <span class="caption font-weight-bold">
                {{ user && user.name ? user.name.charAt(0).toUpperCase() : 'U' }}
              </span>
            </v-avatar>
            <div style="max-width: 125px;">
              <div class="caption font-weight-bold text-truncate">
                {{ (user && user.name) || 'Kasir' }}
              </div>
              <div class="caption grey--text text-truncate" style="font-size: 10px !important;">
                {{ (user && user.email) || '' }}
              </div>
            </div>
          </div>
          <v-btn icon x-small title="Keluar" @click="handleLogout">
            <v-icon small>mdi-logout</v-icon>
          </v-btn>
        </div>
      </template>
    </v-navigation-drawer>

    <v-main>
      <!-- Tampilkan halaman utama jika sudah login -->
      <router-view v-if="isAuthenticated" />

      <!-- Tampilkan form login jika belum login / belum punya token Sanctum -->
      <v-container v-else fill-height class="justify-center align-center">
        <v-card width="400" class="pa-6 rounded-xl" outlined>
          <div class="d-flex align-center mb-5">
            <v-avatar color="#0f4c3a" rounded size="44" class="mr-3">
              <v-icon color="#f5820d">mdi-coffee</v-icon>
            </v-avatar>
            <div>
              <h2 class="title font-weight-bold">Login Kasir</h2>
              <div class="caption grey--text">Masuk untuk mengakses sistem POS</div>
            </div>
          </div>

          <v-alert v-if="loginError" type="error" dense text class="mb-4 caption">
            {{ loginError }}
          </v-alert>

          <v-form @submit.prevent="handleLogin">
            <v-text-field
              v-model="email"
              label="Email"
              type="email"
              prepend-inner-icon="mdi-email-outline"
              outlined
              dense
              required
            ></v-text-field>

            <v-text-field
              v-model="password"
              label="Password"
              type="password"
              prepend-inner-icon="mdi-lock-outline"
              outlined
              dense
              required
            ></v-text-field>

            <v-btn
              type="submit"
              color="#0f4c3a"
              dark
              block
              large
              depressed
              class="rounded-lg mt-2 text-none font-weight-bold"
              :loading="isLoggingIn"
            >
              Masuk ke Kasir
            </v-btn>
          </v-form>
        </v-card>
      </v-container>
    </v-main>
  </v-app>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'App',
  data: () => ({
    email: '',
    password: '',
    isLoggingIn: false,
    loginError: '',
    menus: [
      { title: 'Kasir', icon: 'mdi-view-grid-outline', to: '/' },
      { title: 'Analitik', icon: 'mdi-chart-bar', to: '/analitik' },
      { title: 'Pesanan', icon: 'mdi-receipt-text-outline', to: '/pesanan' },
      { title: 'Produk', icon: 'mdi-cube-outline', to: '/produk' },
      { title: 'Bahan Baku', icon: 'mdi-layers-outline', to: '/bahan-baku' },
      { title: 'Cashflow', icon: 'mdi-wallet-outline', to: '/cashflow' },
      { title: 'Promo', icon: 'mdi-tag-outline', to: '/promo' },
      { title: 'Pengaturan', icon: 'mdi-cog-outline', to: '/pengaturan' },
    ],
  }),
  computed: {
    ...mapGetters(['isAuthenticated', 'user']),
  },
  methods: {
    async handleLogin() {
      this.isLoggingIn = true;
      this.loginError = '';
      try {
        await this.$store.dispatch('login', {
          email: this.email,
          password: this.password,
        });
      } catch (error) {
        this.loginError =
          (error.response && error.response.data && error.response.data.message) ||
          'Login gagal. Periksa kembali email dan password Anda.';
      } finally {
        this.isLoggingIn = false;
      }
    },
    async handleLogout() {
      await this.$store.dispatch('logout');
    },
  },
};
</script>

<style>
.active-nav-item {
  background-color: rgba(255, 255, 255, 0.14) !important;
  color: #ffffff !important;
}
.border-top-teal {
  border-top: 1px solid rgba(255, 255, 255, 0.12);
}
</style>