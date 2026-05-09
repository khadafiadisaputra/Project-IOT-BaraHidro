class DeviceData {
  final double temperature;
  final int ppm;
  final String pumpStatus;

  DeviceData({
    required this.temperature,
    required this.ppm,
    required this.pumpStatus,
  });

  factory DeviceData.fromJson(Map<String, dynamic>? json) {
    // Kalau 'latest_data' dari Railway kosong total
    if (json == null) {
      return DeviceData(temperature: 0.0, ppm: 0, pumpStatus: 'off');
    }

    return DeviceData(
      // Pakai "?? 0.0" artinya: "Kalau suhu gak ada, anggep aja 0.0"
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      ppm: json['ppm'] ?? 0,
      // Nah, ini kuncinya! Karena di Railway kamu pump_status-nya gak ada,
      // baris ini bakal bikin dia jadi 'off' secara otomatis tanpa bikin error.
      pumpStatus: (json['pump_status'] ?? 'off').toString(),
    );
  }
}
