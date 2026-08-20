import React, { useState, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import Dashboard from './Dashboard';
import Login from './login';
import axios from 'axios';

const App = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Verifikasi ke Backend apakah Cookie sesi masih aktif
  useEffect(() => {
    axios.get('/api/device/latest-data')
      .then(() => {
        setIsAuthenticated(true);
        setUsername('Admin User');
        setIsLoading(false);
      })
      .catch(() => {
        setIsAuthenticated(false);
        setIsLoading(false);
      });
  }, []);

  const handleLoginSuccess = (name) => {
    setIsAuthenticated(true);
    setUsername(name || 'Admin User');
  };

  const handleLogout = async () => {
    try {
      await axios.post('/api/logout');
    } catch (e) {
      // Abaikan jika token/sesi sudah kedaluwarsa di server
    }
    setIsAuthenticated(false);
    setUsername('');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center font-sans text-emerald-600 font-semibold">
        Memeriksa Otorisasi Sesi...
      </div>
    );
  }

  return isAuthenticated ? (
    <Dashboard onLogout={handleLogout} username={username} />
  ) : (
    <Login onLoginSuccess={handleLoginSuccess} />
  );
};

const container = document.getElementById('app');
const root = createRoot(container);
root.render(<App />);