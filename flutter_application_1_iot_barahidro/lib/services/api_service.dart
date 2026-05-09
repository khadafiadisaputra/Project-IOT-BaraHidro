import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_data.dart';

class ApiService {
  final String url =
      'https://project-iot-barahidro-production.up.railway.app/api/device/latest-data';

  Future<DeviceData> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeviceData.fromJson(data['latest_data']);
      } else {
        throw Exception('Gagal narik data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Koneksi bermasalah: $e');
    }
  }
}
