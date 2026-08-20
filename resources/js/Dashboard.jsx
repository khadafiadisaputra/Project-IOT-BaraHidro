import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { 
  Activity, Thermometer, Droplets, Power, Wifi, 
  Settings, Clock, Bell, Menu, X, BarChart3, 
  History, Sliders, Zap, AlertCircle
} from 'lucide-react';
import ProperSensorChart from './ProperSensorChart';

// Menggunakan URL relatif agar HttpOnly Cookie Sanctum terkirim otomatis
const API_BASE = '/api/device';

const Dashboard = ({ onLogout, username = 'Admin User' }) => {
  // --- STATE MANAGEMENT ---
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  
  // Settings State
  const [settings, setSettings] = useState({
    mode: 'manual', // default manual
    targetPPM: 800,
    pumpDelay: 5,
  });

  // Sensor & Device State
  const [sensor, setSensor] = useState({
    temp: 0,
    ppm: 0,
    pumpStatus: 'off',
    deviceStatus: 'offline',
    lastUpdate: new Date().toLocaleTimeString(),
  });

  // History State
  const [history, setHistory] = useState([]);
  
  // Notifications
  const [notifications, setNotifications] = useState([]);

  // Loading and Error States
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // --- HELPER STATUS PPM ---
  const renderPpmBadge = () => {
    if (sensor.ppm < settings.targetPPM) {
      return <span className="text-red-500 font-semibold text-[10px] bg-red-50 px-2 py-0.5 rounded-full border border-red-100">Low</span>;
    }
    if (sensor.ppm > settings.targetPPM + 300) {
      return <span className="text-amber-600 font-semibold text-[10px] bg-amber-50 px-2 py-0.5 rounded-full border border-amber-100">High</span>;
    }
    return <span className="text-emerald-600 font-semibold text-[10px] bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100">Optimal</span>;
  };

  // --- FETCH DATA FROM API ---
  const fetchLatestData = async () => {
    try {
      setError(null);
      const [latestResponse, pumpResponse] = await Promise.all([
        axios.get(`${API_BASE}/latest-data`),
        axios.get(`${API_BASE}/pump-status`)
      ]);
      
      const { latest_data, settings: apiSettings } = latestResponse.data;
      const pumpStatusFromApi = pumpResponse.data?.pump_status || 'off';

      let isOnline = false;
      let tempValue = 0;
      let ppmValue = 0;
      let lastUpdateTime = new Date().toLocaleTimeString();

      if (latest_data) {
        let parsedDate = null;
        if (latest_data.recorded_at) {
          parsedDate = new Date(latest_data.recorded_at);
        } else if (latest_data.created_at) {
          parsedDate = new Date(latest_data.created_at);
        }

        if (!isNaN(parsedDate?.getTime?.())) {
          const currentTime = new Date();
          const timeDiffSeconds = (currentTime - parsedDate) / 1000;
          isOnline = timeDiffSeconds >= 0 && timeDiffSeconds <= 120;
          lastUpdateTime = parsedDate.toLocaleTimeString();
        } else {
          isOnline = true;
          if (latest_data.recorded_at) {
            lastUpdateTime = latest_data.recorded_at;
          } else if (latest_data.created_at) {
            lastUpdateTime = latest_data.created_at;
          }
        }

        tempValue = latest_data.temperature || 0;
        ppmValue = latest_data.ppm || 0;
      }

      setSensor(prev => ({
        ...prev,
        temp: tempValue,
        ppm: ppmValue,
        pumpStatus: pumpStatusFromApi.toLowerCase(),
        deviceStatus: isOnline ? 'online' : 'offline',
        lastUpdate: lastUpdateTime,
      }));

      if (apiSettings) {
        setSettings({
          mode: apiSettings.mode || 'manual',
          targetPPM: apiSettings.ppm_min || 800,
          pumpDelay: apiSettings.pump_delay || 5,
        });
      }

      if (latest_data) {
        setHistory(prev => {
          const last = prev.length ? prev[prev.length - 1] : null;
          const newEntry = {
            id: latest_data.id ?? null,
            time: lastUpdateTime,
            ppm: ppmValue,
            temp: tempValue,
            pumpStatus: pumpStatusFromApi.toLowerCase(),
            created_at: latest_data.recorded_at ?? null,
          };

          if (newEntry.id && last && last.id && newEntry.id === last.id) {
            return prev;
          }

          const newHist = [...prev, newEntry];
          if (newHist.length > 100) newHist.shift();
          return newHist;
        });
      }
    } catch (err) {
      console.error('API Error:', err);
      setSensor(prev => ({
        ...prev,
        deviceStatus: 'offline',
      }));
    }
  };

  const fetchHistory = async () => {
    try {
      const resp = await axios.get(`${API_BASE}/history?limit=100`);
      const hist = resp.data.history || [];
      const mapped = hist.map(h => ({
        id: h.id,
        time: h.created_at ? new Date(h.created_at).toLocaleTimeString() : '-',
        created_at: h.created_at,
        ppm: h.ppm,
        temp: h.temperature,
        pumpStatus: resp.data.pump_status || 'off',
      }));
      setHistory(mapped);
    } catch (err) {
      console.error('Failed to load history:', err);
    }
  };

  useEffect(() => {
    fetchHistory();
    fetchLatestData();
    const interval = setInterval(fetchLatestData, 3000);
    return () => clearInterval(interval);
  }, []);

  // --- HANDLERS ---
  const addNotification = (msg) => {
    const newNotif = { id: Date.now(), msg, time: new Date().toLocaleTimeString() };
    setNotifications(prev => [newNotif, ...prev].slice(0, 5));
  };

  // KONTROL POMPA RESPONSIF (KIRIM SEMUA FORMAT KEY BACKEND)
  const handleManualPump = async (action) => {
    const formattedAction = action.toLowerCase();
    
    // 1. Update UI langsung (0 delay)
    setSensor(prev => ({ ...prev, pumpStatus: formattedAction }));
    addNotification(`Pompa ${formattedAction === 'on' ? 'dinyalakan' : 'dimatikan'} secara manual.`);

    try {
      // 2. Kirim payload lengkap agar cocok dengan controller backend
      await axios.post(`${API_BASE}/control`, {
        mode: 'manual',
        pump_action: formattedAction,
        pump_status: formattedAction,
        action: formattedAction,
        status: formattedAction
      });

      // Beri sedikit jeda lalu ambil status terkini dari server
      setTimeout(fetchLatestData, 400);
    } catch (err) {
      console.error('Control Error:', err);
      addNotification('Gagal mengontrol pompa. Periksa server.');
    }
  };

  const saveSettings = async (e) => {
    e.preventDefault();

    const shouldSave = window.confirm('Apakah Anda yakin ingin menyimpan pengaturan ini?');
    if (!shouldSave) return;

    const formData = new FormData(e.target);
    const newSettings = {
      mode: formData.get('mode'),
      targetPPM: parseInt(formData.get('targetPPM')),
      pumpDelay: parseInt(formData.get('pumpDelay')),
    };
    
    try {
      await axios.post(`${API_BASE}/control`, {
        mode: newSettings.mode,
        ppm_min: newSettings.targetPPM,
        pump_delay: newSettings.pumpDelay,
      });
      setSettings(newSettings);
      addNotification('Pengaturan berhasil disimpan.');
      await fetchLatestData();
    } catch (err) {
      addNotification('Gagal menyimpan pengaturan. Coba lagi.');
      console.error('Save Settings Error:', err);
    }
  };

  // --- VIEWS ---
  const renderDashboard = () => (
    <div className="space-y-6 animate-in fade-in duration-500">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-center">
          <AlertCircle size={20} className="mr-2" />
          {error}
        </div>
      )}

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Suhu */}
        <div className="bg-white p-6 rounded-2xl shadow-md border border-slate-200 hover:shadow-lg transition flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm text-slate-500 font-medium">Suhu Air</p>
              <h3 className="text-3xl font-bold text-slate-800 mt-1">{sensor.temp}<span className="text-lg text-slate-400">°C</span></h3>
            </div>
            <div className="p-3 bg-blue-500 text-white rounded-xl shadow-md shadow-blue-500/30">
              <Thermometer size={24} />
            </div>
          </div>
          <div className="mt-4 text-xs text-slate-400 flex items-center">
            <Clock size={12} className="mr-1"/> Update: {sensor.lastUpdate}
          </div>
        </div>

        {/* PPM */}
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col justify-between relative overflow-hidden">
          {sensor.ppm < settings.targetPPM && (
            <div className="absolute top-0 right-0 w-2 h-full bg-blue-500 animate-pulse"></div>
          )}
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm text-slate-500 font-medium">Nutrisi (PPM)</p>
              <h3 className={`text-3xl font-bold mt-1 ${sensor.ppm < settings.targetPPM ? 'text-blue-500' : 'text-slate-800'}`}>
                {sensor.ppm}
              </h3>
            </div>
            <div className="p-3 bg-blue-100 text-blue-600 rounded-xl">
              <Droplets size={24} />
            </div>
          </div>
          <div className="mt-4 text-xs flex items-center justify-between">
            <span className="text-slate-400 font-medium">Target: {settings.targetPPM}</span>
            {renderPpmBadge()}
          </div>
        </div>

        {/* Pompa */}
        <div className={`p-6 rounded-2xl shadow-sm border transition-colors duration-300 flex flex-col justify-between ${
          sensor.pumpStatus === 'on' ? 'bg-blue-500 border-blue-600 text-white' : 'bg-white border-slate-100'
        }`}>
          <div className="flex justify-between items-start">
            <div>
              <p className={`text-sm font-medium ${sensor.pumpStatus === 'on' ? 'text-blue-100' : 'text-slate-500'}`}>Status Pompa</p>
              <h3 className="text-3xl font-bold mt-1 uppercase">{sensor.pumpStatus}</h3>
            </div>
            <div className={`p-3 rounded-xl ${sensor.pumpStatus === 'on' ? 'bg-blue-400 text-white' : 'bg-slate-50 text-slate-400'}`}>
              <Settings size={24} className={sensor.pumpStatus === 'on' ? 'animate-spin' : ''} style={{ animationDuration: '3s'}} />
            </div>
          </div>
          <div className={`mt-4 text-xs flex items-center ${sensor.pumpStatus === 'on' ? 'text-blue-100' : 'text-slate-400'}`}>
            Mode: <strong className="ml-1 uppercase">{settings.mode}</strong>
          </div>
        </div>

        {/* Device Status */}
        <div className={`p-6 rounded-2xl shadow-sm border transition-colors duration-300 flex flex-col justify-between ${sensor.deviceStatus === 'online' ? 'bg-white border-slate-100' : 'bg-red-50 border-red-200'}`}>
          <div className="flex justify-between items-start">
            <div>
              <p className={`text-sm font-medium ${sensor.deviceStatus === 'online' ? 'text-slate-500' : 'text-red-600'}`}>Status Device</p>
              <h3 className={`text-xl font-bold mt-2 flex items-center ${sensor.deviceStatus === 'online' ? 'text-green-600' : 'text-red-600'}`}>
                <span className={`w-3 h-3 rounded-full mr-2 ${sensor.deviceStatus === 'online' ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></span>
                {sensor.deviceStatus === 'online' ? 'Online' : 'Offline'}
              </h3>
            </div>
            <div className={`p-3 rounded-xl ${sensor.deviceStatus === 'online' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'}`}>
              <Wifi size={24} />
            </div>
          </div>
          <div className={`mt-4 text-xs ${sensor.deviceStatus === 'online' ? 'text-slate-400' : 'text-red-600 font-medium'}`}>
            {sensor.deviceStatus === 'online' ? 'ESP32 terhubung' : 'ESP32 Terputus'}
          </div>
        </div>
      </div>

      {/* Charts Area */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div>
          <ProperSensorChart 
            data={history} 
            dataKey="ppm" 
            color="#3b82f6"
            unit="PPM"
            title="Grafik Nutrisi (PPM) Realtime"
            yAxisLabel="PPM"
          />
        </div>
        <div>
          <ProperSensorChart 
            data={history} 
            dataKey="temp" 
            color="#f97316"
            unit="°C"
            title="Grafik Suhu Air Realtime"
            yAxisLabel="Suhu (°C)"
          />
        </div>
      </div>
    </div>
  );

  const renderControl = () => (
    <div className="max-w-2xl mx-auto space-y-6 animate-in fade-in duration-500">
      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div className="p-6 border-b border-slate-100">
          <h2 className="text-xl font-bold text-slate-800 flex items-center">
            <Sliders className="mr-2 text-indigo-500"/> Kontrol Pompa Nutrisi
          </h2>
          <p className="text-sm text-slate-500 mt-1">Override sistem otomatis dan kontrol pompa secara manual.</p>
        </div>
        
        <div className="p-6">
          <div className="mb-8">
            <label className="block text-sm font-medium text-slate-700 mb-3">Mode Saat Ini</label>
            <div className="flex bg-slate-100 p-1 rounded-lg">
              <div className={`flex-1 text-center py-2 rounded-md font-medium text-sm transition-all ${settings.mode === 'auto' ? 'bg-white shadow text-indigo-600' : 'text-slate-500 opacity-50'}`}>
                AUTO
              </div>
              <div className={`flex-1 text-center py-2 rounded-md font-medium text-sm transition-all ${settings.mode === 'manual' ? 'bg-white shadow text-indigo-600' : 'text-slate-500 opacity-50'}`}>
                MANUAL
              </div>
            </div>
            <p className="text-xs text-slate-400 mt-2 text-center">*Ubah mode di menu Settings</p>
          </div>

          <div className={`transition-opacity duration-300 ${settings.mode === 'auto' ? 'opacity-40 pointer-events-none' : 'opacity-100'}`}>
            <div className="flex flex-col items-center justify-center py-8 border-2 border-dashed border-slate-200 rounded-xl">
              <div className={`w-32 h-32 rounded-full flex items-center justify-center mb-6 transition-all duration-500 ${sensor.pumpStatus === 'on' ? 'bg-blue-100 shadow-[0_0_40px_rgba(59,130,246,0.4)]' : 'bg-slate-100'}`}>
                <Power size={48} className={`transition-colors duration-500 ${sensor.pumpStatus === 'on' ? 'text-blue-500' : 'text-slate-400'}`} />
              </div>
              
              <div className="flex gap-4">
                <button 
                  type="button"
                  onClick={() => handleManualPump('on')}
                  className={`px-8 py-3 rounded-xl font-bold transition-all ${
                    sensor.pumpStatus === 'on' 
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/30' 
                      : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
                  }`}
                >
                  ON
                </button>
                <button 
                  type="button"
                  onClick={() => handleManualPump('off')}
                  className={`px-8 py-3 rounded-xl font-bold transition-all ${
                    sensor.pumpStatus === 'off' 
                      ? 'bg-red-600 text-white shadow-lg shadow-red-500/30' 
                      : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
                  }`}
                >
                  OFF
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderHistory = () => (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100 animate-in fade-in duration-500">
      <div className="p-6 border-b border-slate-100">
        <h2 className="text-xl font-bold text-slate-800 flex items-center">
          <History className="mr-2 text-slate-500"/> Riwayat Data
        </h2>
        <p className="text-sm text-slate-500 mt-1">Data logger sensor dan status pompa.</p>
      </div>
      
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 text-slate-500 text-sm border-b border-slate-100">
              <th className="p-4 font-medium">Waktu</th>
              <th className="p-4 font-medium">Suhu (°C)</th>
              <th className="p-4 font-medium">PPM</th>
              <th className="p-4 font-medium">Status Pompa</th>
            </tr>
          </thead>
          <tbody>
            {[...history].reverse().map((row, i) => (
              <tr key={i} className="border-b border-slate-50 hover:bg-slate-50/50 transition-colors">
                <td className="p-4 text-sm text-slate-600">{row.time}</td>
                <td className="p-4 text-sm font-medium text-orange-500">{row.temp}</td>
                <td className="p-4 text-sm font-medium text-blue-500">{row.ppm}</td>
                <td className="p-4 text-sm">
                  <span className={`px-2 py-1 rounded-md text-xs font-bold uppercase ${row.pumpStatus === 'on' ? 'bg-emerald-100 text-emerald-600' : 'bg-slate-100 text-slate-500'}`}>
                    {row.pumpStatus}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );

  const renderSettings = () => (
    <div className="max-w-2xl mx-auto bg-white rounded-2xl shadow-sm border border-slate-100 animate-in fade-in duration-500">
      <div className="p-6 border-b border-slate-100">
        <h2 className="text-xl font-bold text-slate-800 flex items-center">
          <Settings className="mr-2 text-slate-500"/> Pengaturan Sistem
        </h2>
        <p className="text-sm text-slate-500 mt-1">Konfigurasi batas nutrisi dan perilaku otomatisasi.</p>
      </div>
      
      <form onSubmit={saveSettings} className="p-6 space-y-6">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">Mode Operasi</label>
          <select 
            name="mode" 
            defaultValue={settings.mode}
            className="w-full border border-slate-200 rounded-xl p-3 focus:ring-2 focus:ring-indigo-500 outline-none text-slate-700 bg-slate-50"
          >
            <option value="manual">Manual (Kontrol User)</option>
            <option value="auto">Otomatis (Berdasarkan Sensor)</option>
          </select>
          <p className="text-xs text-slate-500 mt-2">
            Pilih <b>Manual</b> agar kontrol tombol ON/OFF berlaku penuh.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Standar Nutrisi (PPM Min)</label>
            <div className="relative">
              <input 
                type="number" 
                name="targetPPM" 
                defaultValue={settings.targetPPM}
                className="w-full border border-slate-200 rounded-xl p-3 pl-10 focus:ring-2 focus:ring-indigo-500 outline-none text-slate-700 bg-slate-50"
              />
              <Droplets size={18} className="absolute left-3 top-3.5 text-blue-400" />
            </div>
            <p className="text-xs text-slate-500 mt-2">Nilai batas bawah PPM.</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2 flex items-center">
              Smart Delay Pompa <Zap size={14} className="ml-1 text-amber-500"/>
            </label>
            <div className="relative">
              <input 
                type="number" 
                name="pumpDelay" 
                defaultValue={settings.pumpDelay}
                className="w-full border border-slate-200 rounded-xl p-3 pl-10 pr-12 focus:ring-2 focus:ring-indigo-500 outline-none text-slate-700 bg-slate-50"
              />
              <Clock size={18} className="absolute left-3 top-3.5 text-slate-400" />
              <span className="absolute right-4 top-3.5 text-sm text-slate-400 font-medium">Detik</span>
            </div>
            <p className="text-xs text-slate-500 mt-2">Lama pompa menyala sebelum mati untuk cek ulang.</p>
          </div>
        </div>

        <div className="pt-4 border-t border-slate-100 flex justify-end">
          <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-xl font-medium transition-colors shadow-md">
            Simpan Pengaturan
          </button>
        </div>
      </form>
    </div>
  );

  // --- LAYOUT & NAVIGATION ---
  const navItems = [
    { id: 'dashboard', icon: Activity, label: 'Dashboard' },
    { id: 'control', icon: Sliders, label: 'Control' },
    { id: 'history', icon: History, label: 'History' },
    { id: 'settings', icon: Settings, label: 'Settings' },
  ];

  return (
    <div className="flex h-screen bg-slate-100 font-sans text-slate-800 overflow-hidden">
      {/* Mobile Overlay */}
      <div className={`fixed inset-0 bg-slate-800/50 z-20 transition-opacity lg:hidden ${isMobileMenuOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`} onClick={() => setIsMobileMenuOpen(false)}></div>
      
      {/* Sidebar */}
      <aside className={`fixed lg:static inset-y-0 left-0 w-64 bg-slate-900 text-white shadow z-30 transform transition-transform duration-300 flex flex-col ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        <div className="h-16 flex items-center px-6 border-b border-slate-800">
          <div className="w-10 h-10 flex items-center justify-center mr-3">
            <img 
              src="/logo.jpeg" 
              className="w-8 h-8 object-contain rounded" 
              alt="Logo"
              onError={(e) => { e.target.style.display = 'none'; }}
            />
          </div>
          <h1 className="font-bold text-lg tracking-tight">BaraHydroSolutions<span className="text-emerald-500">.</span></h1>
        </div>
        
        <nav className="flex-1 px-4 py-6 space-y-1">
          {navItems.map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => { setActiveTab(item.id); setIsMobileMenuOpen(false); }}
                className={`w-full flex items-center px-4 py-3 rounded-xl transition-all ${
                  isActive ? 'bg-blue-500 text-white font-semibold shadow-lg shadow-blue-500/30' : 'text-gray-400 hover:bg-white/10 hover:text-white'
                }`}
              >
                <Icon size={20} className="mr-3" />
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-800">
          <div className="flex items-center px-4 py-3 rounded-xl bg-blue-500 text-white shadow-lg shadow-blue-500/30">
            <div className="w-8 h-8 bg-indigo-100 text-indigo-600 rounded-full flex items-center justify-center font-bold text-sm">
              {username.charAt(0).toUpperCase()}
            </div>
            <div className="ml-3 truncate">
              <p className="text-sm font-semibold truncate">{username}</p>
              <p className="text-xs text-blue-100">Authenticated User</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Header */}
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-4 lg:px-8 z-10">
          <div className="flex items-center">
            <button className="lg:hidden p-2 text-slate-500 hover:bg-slate-50 rounded-lg mr-2" onClick={() => setIsMobileMenuOpen(true)}>
              <Menu size={20} />
            </button>
            <h2 className="text-lg font-semibold capitalize hidden sm:block">{activeTab}</h2>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="hidden sm:flex items-center px-3 py-1 bg-blue-50 text-blue-600 rounded-full text-xs font-medium border border-blue-100">
              <span className={`w-2 h-2 rounded-full mr-2 ${sensor.deviceStatus === 'online' ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></span> 
              {sensor.deviceStatus === 'online' ? 'System Active' : 'System Standby'}
            </div>
            
            {/* User Dropdown */}
            <div className="relative group">
              <button className="p-2 text-slate-400 hover:bg-slate-50 rounded-full transition-colors">
                <div className="w-7 h-7 bg-gradient-to-r from-green-500 to-blue-600 rounded-full flex items-center justify-center text-white text-xs font-bold shadow">
                  {username.charAt(0).toUpperCase()}
                </div>
              </button>
              
              <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-slate-100 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all transform origin-top-right z-50">
                <div className="p-4 border-b border-slate-100">
                  <p className="text-sm font-semibold text-slate-700">Selamat Datang</p>
                  <p className="text-xs text-slate-500 mt-1 truncate">{username}</p>
                </div>
                <button
                  onClick={onLogout}
                  className="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 rounded-b-xl transition-colors font-medium"
                >
                  Logout
                </button>
              </div>
            </div>
          </div>
        </header>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-4 lg:p-8 scroll-smooth">
          <div className="max-w-6xl mx-auto space-y-6">
            {activeTab === 'dashboard' && renderDashboard()}
            {activeTab === 'control' && renderControl()}
            {activeTab === 'history' && renderHistory()}
            {activeTab === 'settings' && renderSettings()}
          </div>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;