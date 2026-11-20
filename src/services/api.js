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

let isRedirecting = false;

// Request Interceptor
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    config.headers = config.headers || {};

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Biarkan browser/Axios menentukan multipart boundary otomatis saat mengirim FormData
    if (typeof FormData !== 'undefined' && config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }

    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor
apiClient.interceptors.response.use(
  (response) => {
    isRedirecting = false;
    return response;
  },
  (error) => {
    const reqUrl = (error && error.config && error.config.url) || '';

    if (error && error.response) {
      const status = error.response.status;

      console.error(
        'API Error:',
        reqUrl,
        status,
        error.response.data
      );

      const isLoginRequest = reqUrl.includes('/login');

      if (status === 401 && !isLoginRequest && !isRedirecting) {
        isRedirecting = true;
        localStorage.removeItem('token');

        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        } else {
          isRedirecting = false;
        }
      }
    } else if (error && error.code === 'ECONNABORTED') {
      console.error('API Timeout:', reqUrl);
    } else {
      console.error(
        'Network Error:',
        reqUrl,
        error ? error.message : 'Unknown error'
      );
    }

    return Promise.reject(error);
  }
);

export default apiClient;