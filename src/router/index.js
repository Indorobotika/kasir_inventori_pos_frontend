import Vue from 'vue';
import VueRouter from 'vue-router';
import Home from '../views/Home.vue';
import AnalyticsView from '../views/AnalyticsView.vue';
import OrdersView from '../views/OrdersView.vue';
import ProductsView from '../views/ProductsView.vue';
import RawMaterialsView from '../views/RawMaterialsView.vue';
import CashflowView from '../views/CashflowView.vue';
import PromotionsView from '../views/PromotionsView.vue';
import SettingsView from '../views/SettingsView.vue';

Vue.use(VueRouter);

const routes = [
  { path: '/', name: 'Kasir', component: Home },
  { path: '/analitik', name: 'Analitik', component: AnalyticsView },
  { path: '/pesanan', name: 'Pesanan', component: OrdersView },
  { path: '/produk', name: 'Produk', component: ProductsView },
  { path: '/bahan-baku', name: 'BahanBaku', component: RawMaterialsView },
  { path: '/cashflow', name: 'Cashflow', component: CashflowView },
  { path: '/promo', name: 'Promo', component: PromotionsView },
  { path: '/pengaturan', name: 'Pengaturan', component: SettingsView },
  { path: '*', redirect: '/' },
];

export default new VueRouter({
  mode: 'history',
  routes,
});