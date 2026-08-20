// simulator.js - Synchronized ESP32 Mock Streamer
const BASE_URL = "http://127.0.0.1:8000/api";
const LOGIN_URL = `${BASE_URL}/login`;
const SENSOR_URL = `${BASE_URL}/device/sensor-data`;
const PUMP_URL = `${BASE_URL}/device/pump-status`;

const CREDENTIALS = {
  email: "esp32@barahidro.local",
  password: "rahasia_esp32_123!"
};

async function getToken() {
  console.log("[*] Login Sanctum Token...");
  try {
    const res = await fetch(LOGIN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json" },
      body: JSON.stringify(CREDENTIALS)
    });
    if (res.ok) {
      const data = await res.json();
      const token = data.token || data.access_token;
      console.log("[+] Login sukses! Token terpasang.\n");
      return token;
    }
  } catch (e) {
    console.log("[-] Error koneksi:", e.message);
  }
  return null;
}

async function main() {
  let token = await getToken();
  if (!token) {
    console.log("[-] Pastikan backend Laravel menyala.");
    return;
  }

  let basePpm = 650.0;
  let baseTemp = 27.5;

  console.log("[*] ESP32 Simulator Aktif (Tekan Ctrl + C untuk stop)...\n");

  setInterval(async () => {
    const headers = {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/json",
      "Content-Type": "application/json"
    };

    // Ambil status pompa asli terbaru dari backend
    let activePump = "off";
    try {
      const pRes = await fetch(PUMP_URL, { headers });
      if (pRes.ok) {
        const pData = await pRes.json();
        activePump = (pData.pump_status || pData.status || "off").toLowerCase();
      }
    } catch (e) {}

    // Variasi acak halus
    basePpm += (Math.random() * 30 - 15);
    basePpm = Math.max(400, Math.min(1200, basePpm));

    baseTemp += (Math.random() * 0.6 - 0.3);
    baseTemp = Math.max(22, Math.min(35, baseTemp));

    const payload = {
      ppm: parseFloat(basePpm.toFixed(1)),
      temperature: parseFloat(baseTemp.toFixed(1)),
      pump_status: activePump
    };

    try {
      const res = await fetch(SENSOR_URL, {
        method: "POST",
        headers: headers,
        body: JSON.stringify(payload)
      });

      if (res.ok) {
        console.log(`[SENT] Suhu: ${payload.temperature}°C | PPM: ${payload.ppm} | Pompa: ${payload.pump_status.toUpperCase()}`);
      } else if (res.status === 401) {
        token = await getToken();
      }
    } catch (err) {
      console.log("[-] Error kirim:", err.message);
    }
  }, 3000);
}

main();