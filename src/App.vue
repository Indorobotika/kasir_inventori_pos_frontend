<template>
  <v-app :style="{ backgroundColor: isDarkMode ? '#121212' : '#f8f7f4' }">
    <v-navigation-drawer
      v-if="isAuthenticated"
      app
      permanent
      :mini-variant.sync="isMini"
      mini-variant-width="72"
      width="235"
      :color="isDarkMode ? '#1e1e1e' : '#0f4c3a'"
      dark
    >
      <!-- Header Logo & Tombol Expand/Collapse -->
      <div class="pa-3 d-flex align-center" :class="isMini ? 'justify-center' : 'justify-space-between'">
        <div class="d-flex align-center" style="min-width: 0;">
          <v-avatar
            :color="setting && setting.logo_path_url ? 'transparent' : '#f5820d'"
            rounded
            size="38"
            :class="isMini ? '' : 'mr-3'"
            style="cursor: pointer;"
            @click="isMini = !isMini"
          >
            <img
              v-if="setting && setting.logo_path_url"
              :src="setting.logo_path_url"
              alt="Logo"
              style="width: 100%; height: 100%; object-fit: cover;"
            />
            <v-icon v-else color="black">mdi-coffee</v-icon>
          </v-avatar>
          <div v-if="!isMini" class="text-truncate">
            <div class="font-weight-bold subtitle-2 white--text text-truncate">
              {{ (setting && setting.store_name) || 'Indorobotika' }}
            </div>
          </div>
        </div>

        <v-btn v-if="!isMini" icon x-small title="Ciutkan Sidebar" @click="isMini = true">
          <v-icon small>mdi-chevron-left</v-icon>
        </v-btn>
      </div>

      <!-- Tombol Expand saat Sidebar Ciut -->
      <div v-if="isMini" class="text-center pb-2">
        <v-btn icon x-small title="Perluas Sidebar" @click="isMini = false">
          <v-icon small>mdi-chevron-right</v-icon>
        </v-btn>
      </div>

      <!-- Daftar Menu Navigasi -->
      <v-list nav dense class="px-3 mt-1">
        <v-tooltip
          v-for="menu in menus"
          :key="menu.to"
          right
          :disabled="!isMini"
        >
          <template v-slot:activator="{ on, attrs }">
            <v-list-item
              v-bind="attrs"
              v-on="on"
              :to="menu.to"
              exact
              active-class="active-nav-item"
              class="rounded-lg mb-1"
            >
              <v-list-item-icon :class="isMini ? 'mx-auto' : 'mr-3'">
                <v-icon small>{{ menu.icon }}</v-icon>
              </v-list-item-icon>
              <v-list-item-content v-if="!isMini">
                <v-list-item-title class="body-2 font-weight-medium">
                  {{ menu.title }}
                </v-list-item-title>
              </v-list-item-content>
            </v-list-item>
          </template>
          <span>{{ menu.title }}</span>
        </v-tooltip>
      </v-list>

      <template v-slot:append>
        <!-- Tombol Toggle Dark Mode -->
        <div
          class="px-3 py-2 border-top-teal d-flex align-center"
          :class="isMini ? 'justify-center' : 'justify-space-between'"
        >
          <div v-if="!isMini" class="d-flex align-center">
            <v-icon small class="mr-2 grey--text text--lighten-2">
              {{ isDarkMode ? 'mdi-weather-night' : 'mdi-white-balance-sunny' }}
            </v-icon>
            <span class="caption grey--text text--lighten-2 font-weight-medium">Mode Gelap</span>
          </div>

          <v-btn
            v-if="isMini"
            icon
            small
            :title="isDarkMode ? 'Aktifkan Mode Terang' : 'Aktifkan Mode Gelap'"
            @click="isDarkMode = !isDarkMode"
          >
            <v-icon small color="#f5820d">
              {{ isDarkMode ? 'mdi-weather-night' : 'mdi-white-balance-sunny' }}
            </v-icon>
          </v-btn>

          <v-switch
            v-else
            v-model="isDarkMode"
            dense
            hide-details
            inset
            color="#f5820d"
          ></v-switch>
        </div>

        <!-- Profil & Logout -->
        <div
          class="pa-3 border-top-teal d-flex align-center"
          :class="isMini ? 'flex-column justify-center' : 'justify-space-between'"
        >
          <div class="d-flex align-center">
            <v-avatar :color="isDarkMode ? '#333333' : '#236854'" size="34" :class="isMini ? 'mb-2' : 'mr-2'">
              <span class="caption font-weight-bold white--text">
                {{ user && user.name ? user.name.charAt(0).toUpperCase() : "U" }}
              </span>
            </v-avatar>
            <div v-if="!isMini" style="max-width: 125px">
              <div class="caption font-weight-bold text-truncate white--text">
                {{ (user && user.name) || "Kasir" }}
              </div>
              <div
                class="caption grey--text text-truncate"
                style="font-size: 10px !important"
              >
                {{ (user && user.email) || "" }}
              </div>
            </div>
          </div>
          <v-btn icon x-small title="Keluar" class="white--text" @click="handleLogout">
            <v-icon small>mdi-logout</v-icon>
          </v-btn>
        </div>
      </template>
    </v-navigation-drawer>

    <v-main :style="{ backgroundColor: isDarkMode ? '#121212' : '#f8f7f4' }">
      <!-- Tampilkan halaman utama jika sudah login -->
      <router-view v-if="isAuthenticated" />

      <!-- Tampilkan form login jika belum login -->
      <v-container v-else fill-height class="justify-center align-center">
        <v-card width="400" class="pa-6 rounded-xl" :color="isDarkMode ? '#1e1e1e' : 'white'" :dark="isDarkMode" outlined>
          <div class="d-flex align-center mb-5">
            <v-avatar
              :color="setting && setting.logo_path_url ? 'transparent' : (isDarkMode ? '#333333' : '#0f4c3a')"
              rounded
              size="44"
              class="mr-3"
            >
              <img
                v-if="setting && setting.logo_path_url"
                :src="setting.logo_path_url"
                alt="Logo"
                style="width: 100%; height: 100%; object-fit: cover;"
              />
              <v-icon v-else color="#f5820d">mdi-coffee</v-icon>
            </v-avatar>
            <div>
              <h2 class="title font-weight-bold">
                {{ (setting && setting.store_name) || 'Login Kasir' }}
              </h2>
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
import { mapGetters } from "vuex";

export default {
  name: "App",
  data: () => ({
    email: "",
    password: "",
    isLoggingIn: false,
    loginError: "",
    isMini: localStorage.getItem("pos_sidebar_mini") === "true",
    isDarkMode: localStorage.getItem("pos_dark_mode") === "true",
    menus: [
      { title: "Kasir", icon: "mdi-view-grid-outline", to: "/" },
      { title: "Analitik", icon: "mdi-chart-bar", to: "/analitik" },
      { title: "Pesanan", icon: "mdi-receipt-text-outline", to: "/pesanan" },
      { title: "Produk", icon: "mdi-cube-outline", to: "/produk" },
      { title: "Bahan Baku", icon: "mdi-layers-outline", to: "/bahan-baku" },
      { title: "Cashflow", icon: "mdi-wallet-outline", to: "/cashflow" },
      { title: "Promo", icon: "mdi-tag-outline", to: "/promo" },
      { title: "Pengaturan", icon: "mdi-cog-outline", to: "/pengaturan" },
    ],
  }),
  computed: {
    ...mapGetters(["isAuthenticated", "user", "setting"]),
  },
  watch: {
    isMini(val) {
      localStorage.setItem("pos_sidebar_mini", val);
    },
    isDarkMode(val) {
      this.$vuetify.theme.dark = val;
      localStorage.setItem("pos_dark_mode", val);
    },
  },
  created() {
    this.$vuetify.theme.dark = this.isDarkMode;
    
    // Diperbaiki: Hanya fetch data jika token benar-benar ada untuk mencegah looping 401
    if (localStorage.getItem("token")) {
      this.$store.dispatch("fetchPosData").catch(() => {});
    }
  },
  methods: {
    async handleLogin() {
      this.isLoggingIn = true;
      this.loginError = "";
      try {
        await this.$store.dispatch("login", {
          email: this.email,
          password: this.password,
        });
        await this.$store.dispatch("fetchPosData");
      } catch (error) {
        this.loginError =
          (error.response && error.response.data && error.response.data.message) ||
          "Login gagal. Periksa kembali email dan password Anda.";
      } finally {
        this.isLoggingIn = false;
      }
    },
    async handleLogout() {
      await this.$store.dispatch("logout");
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