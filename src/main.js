import Vue from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';
import Vuetify from 'vuetify';
import 'vuetify/dist/vuetify.min.css';
import apiClient from './services/api';

Vue.use(Vuetify);
const vuetify = new Vuetify({
  theme: {
    themes: {
      light: {
        primary: '#0f4c3a',
        secondary: '#f5820d',
        accent: '#1d5b49',
      },
    },
  },
});

// Daftarkan apiClient agar bisa diakses global via this.$api jika diperlukan, 
// sementara service terpusat tetap menggunakan instance yang sama.
Vue.prototype.$api = apiClient;
Vue.config.productionTip = false;

new Vue({
  router,
  store,
  vuetify,
  render: (h) => h(App),
}).$mount('#app');