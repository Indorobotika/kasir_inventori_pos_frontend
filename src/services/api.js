import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://127.0.0.1:8000/api',
  timeout: Number(process.env.VUE_APP_TIMEOUT) || 10000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  withCredentials: true,
});

// Request Interceptor: Menyisipkan token otomatis ke header jika user sudah login
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Otomatis bersihkan token jika sesi/token expired (401)
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;