import React, { useState } from 'react';
import { AlertCircle, Eye, EyeOff } from 'lucide-react';
import axios from 'axios';

const Login = ({ onLoginSuccess }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // 1. Dapatkan stempel CSRF Cookie dari Laravel Sanctum
      await axios.get('/sanctum/csrf-cookie');

      // 2. Kirim kredensial asli ke endpoint Backend
      const response = await axios.post('/api/login', {
        email: email,
        password: password,
      });

      // 3. Pasang Bearer Token ke header Axios sebagai pengaman ganda
      if (response.data && response.data.token) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${response.data.token}`;
      }

      // 4. Login sukses
      setLoading(false);
      onLoginSuccess(response.data.user?.name || 'Admin User');
    } catch (err) {
      setLoading(false);
      if (err.response && err.response.data && err.response.data.message) {
        setError(err.response.data.message);
      } else {
        setError('Email atau password salah. Silakan coba lagi.');
      }
      setPassword('');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="mb-6 flex justify-center">
            <img 
              src="/logo.jpeg" 
              alt="Bara Hidro Logo" 
              className="h-24 w-24 object-contain rounded-lg shadow-lg"
              onError={(e) => { e.target.style.display = 'none'; }}
            />
          </div>
          <h1 className="text-3xl font-bold text-gray-800 mb-2">Bara Hidro</h1>
          <p className="text-gray-600">Sistem Monitoring Hidroponik</p>
        </div>

        {/* Login Card */}
        <div className="bg-white rounded-lg shadow-xl p-8">
          <h2 className="text-2xl font-bold text-gray-800 mb-6 text-center">
            Login
          </h2>

          <form onSubmit={handleLogin} className="space-y-4">
            {/* Email Field */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email Pengguna
              </label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@barahidro.local"
                required
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition"
                disabled={loading}
              />
            </div>

            {/* Password Field */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Kata Sandi
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition"
                  disabled={loading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700"
                  disabled={loading}
                >
                  {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            {/* Error Message */}
            {error && (
              <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700">
                <AlertCircle size={20} className="flex-shrink-0" />
                <span className="text-sm">{error}</span>
              </div>
            )}

            {/* Login Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-green-500 to-blue-600 hover:from-green-600 hover:to-blue-700 text-white font-bold py-2 px-4 rounded-lg transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed mt-6 shadow-md"
            >
              {loading ? 'Memverifikasi Sistem...' : 'Login'}
            </button>
          </form>

          {/* Credentials Info Helper */}
          <div className="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <p className="text-xs text-gray-600 mb-2">
              <span className="font-semibold">Akun Uji Coba:</span>
            </p>
            <p className="text-sm text-gray-700">
              Email: <span className="font-mono font-bold">esp32@barahidro.local</span>
            </p>
            <p className="text-sm text-gray-700">
              Password: <span className="font-mono font-bold">rahasia_esp32_123!</span>
            </p>
          </div>
        </div>

        {/* Footer */}
        <p className="text-center text-gray-600 text-sm mt-6">
          © 2026 Bara Hidro. Semua hak dilindungi.
        </p>
      </div>
    </div>
  );
};

export default Login;