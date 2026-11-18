
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://127.0.0.1:8000/api',
  timeout: Number(process.env.VUE_APP_TIMEOUT) || 30000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  withCredentials: false,
});

// Request Interceptor
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');

    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor
let isRedirecting = false;

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      const status = error.response.status;

      console.error(
        'API Error:',
        error.config?.url,
        status,
        error.response.data
      );

      if (status === 401 && !isRedirecting) {
        isRedirecting = true;

        localStorage.removeItem('token');

        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
      }
    } else if (error.code === 'ECONNABORTED') {
      console.error('API Timeout:', error.config?.url);
    } else {
      console.error(
        'Network Error:',
        error.config?.url,
        error.message
      );
    }

    return Promise.reject(error);
  }
);

export default apiClient;
