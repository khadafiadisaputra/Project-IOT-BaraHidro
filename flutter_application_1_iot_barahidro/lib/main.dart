import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'services/api_service.dart';
import 'models/device_data.dart';

void main() => runApp(const BaraHidroApp());

class BaraHidroApp extends StatelessWidget {
  const BaraHidroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BaraHydroSolutions',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ControlPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- HALAMAN DASHBOARD ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<DeviceData> _deviceData;

  final List<double> ppmData = [10, 10, 10, 10, 10, 10, 10, 45, 58, 58, 58, 58];
  final List<double> suhuData = [29.8, 29.9, 30.0, 30.1, 30.2, 30.25, 30.25, 30.25, 30.20, 30.15];

  @override
  void initState() {
    super.initState();
    _deviceData = _apiService.fetchSensorData();
  }

  void _refreshData() {
    setState(() {
      _deviceData = _apiService.fetchSensorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("BaraHydro Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh, color: Colors.blue)),
        ],
      ),
      body: FutureBuilder<DeviceData>(
        future: _deviceData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final data = snapshot.hasData ? snapshot.data! : DeviceData(temperature: 30.25, ppm: 58, pumpStatus: 'off');

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(
                children: [
                  Expanded(child: _buildModernCard("Suhu Air", "${data.temperature}°C", Icons.thermostat, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernCard("Nutrisi", "${data.ppm} PPM", Icons.opacity, Colors.blue)),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernCard("Status Pompa", data.pumpStatus.toUpperCase(), Icons.power, data.pumpStatus == 'on' ? Colors.green : Colors.grey),
              const SizedBox(height: 16),
              // Panggil komponen Interactive Chart untuk Suhu
              InteractiveChartCard(title: "Grafik Suhu Realtime (°C)", icon: Icons.show_chart, color: Colors.orange, dataPoints: suhuData, isInt: false),
              const SizedBox(height: 16),
              // Panggil komponen Interactive Chart untuk PPM
              InteractiveChartCard(title: "Grafik PPM Realtime", icon: Icons.bar_chart, color: Colors.blue, dataPoints: ppmData, isInt: true),
              const SizedBox(height: 24),
              _buildStatusDevice(data.temperature > 0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDevice(bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isOnline ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: isOnline ? Colors.green[100]! : Colors.red[100]!)),
      child: Row(
        children: [
          Icon(isOnline ? Icons.check_circle : Icons.error, color: isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Text("Status Device: ", style: TextStyle(color: isOnline ? Colors.green[800] : Colors.red[800])),
          Text(isOnline ? "ONLINE" : "OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? Colors.green[800] : Colors.red[800])),
        ],
      ),
    );
  }
}

// --- KOMPONEN WIDGET KHUSUS GRAFIK INTERAKTIF ---
class InteractiveChartCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<double> dataPoints;
  final bool isInt;

  const InteractiveChartCard({super.key, required this.title, required this.icon, required this.color, required this.dataPoints, required this.isInt});

  @override
  State<InteractiveChartCard> createState() => _InteractiveChartCardState();
}

class _InteractiveChartCardState extends State<InteractiveChartCard> {
  double? _touchX; // Variabel untuk menyimpan posisi sentuhan jari/kursor

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 18),
                const SizedBox(width: 8),
                Text(widget.title, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            // Area untuk mendeteksi sentuhan
            GestureDetector(
              onPanUpdate: (details) => setState(() => _touchX = details.localPosition.dx),
              onPanDown: (details) => setState(() => _touchX = details.localPosition.dx),
              onPanEnd: (_) => setState(() => _touchX = null),
              onPanCancel: () => setState(() => _touchX = null),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: InteractiveLineChartPainter(widget.dataPoints, widget.color, isInt: widget.isInt, touchX: _touchX),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PELUKIS GRAFIK (SEKARANG PUNYA FITUR TOOLTIP) ---
class InteractiveLineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isInt;
  final double? touchX;

  InteractiveLineChartPainter(this.data, this.color, {this.isInt = false, this.touchX});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()..color = color..strokeWidth = 3.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintFill = Paint()..style = PaintingStyle.fill..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, size.height), [color.withOpacity(0.3), color.withOpacity(0.0)]);
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 1.0..style = PaintingStyle.stroke;

    double maxData = data.reduce((a, b) => a > b ? a : b);
    double minData = data.reduce((a, b) => a < b ? a : b);
    if (maxData == minData) { maxData += 1; minData -= 1; }
    double range = maxData - minData;

    double paddingLeft = 35.0;
    double chartWidth = size.width - paddingLeft;
    double stepX = chartWidth / (data.length - 1);

    // Gambar label grid (Y-Axis)
    void drawLabelAndGrid(double value, double y) {
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), paintGrid);
      final text = isInt ? value.toInt().toString() : value.toStringAsFixed(1);
      final textPainter = TextPainter(text: TextSpan(text: text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    drawLabelAndGrid(maxData, 0);
    drawLabelAndGrid(minData + (range / 2), size.height / 2);
    drawLabelAndGrid(minData, size.height);

    final path = Path();
    final fillPath = Path();

    // Mapping koordinat titik
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = paddingLeft + (i * stepX);
      double y = size.height - ((data[i] - minData) / range * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(paddingLeft + chartWidth, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // --- LOGIKA TOOLTIP SAAT DISENTUH ---
    if (touchX != null && touchX! >= paddingLeft && touchX! <= size.width) {
      // Cari titik index terdekat dari posisi kursor
      int nearestIndex = ((touchX! - paddingLeft) / stepX).round().clamp(0, data.length - 1);
      Offset activePoint = points[nearestIndex];
      String tooltipValue = isInt ? data[nearestIndex].toInt().toString() : data[nearestIndex].toStringAsFixed(2);

      // Gambar garis vertikal
      canvas.drawLine(Offset(activePoint.dx, 0), Offset(activePoint.dx, size.height), Paint()..color = color.withOpacity(0.5)..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // Gambar titik fokus (bulatan)
      canvas.drawCircle(activePoint, 6.0, Paint()..color = color);
      canvas.drawCircle(activePoint, 3.0, Paint()..color = Colors.white);

      // Gambar Kotak Tooltip
      final textPainter = TextPainter(text: TextSpan(text: tooltipValue, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
      textPainter.layout();

      // Atur posisi tooltip supaya tidak kepotong ke atas
      double tooltipY = activePoint.dy - 25;
      if (tooltipY < 0) tooltipY = activePoint.dy + 15;

      final tooltipRect = Rect.fromCenter(center: Offset(activePoint.dx, tooltipY), width: textPainter.width + 16, height: textPainter.height + 10);
      canvas.drawRRect(RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6)), Paint()..color = Colors.black87);
      textPainter.paint(canvas, Offset(activePoint.dx - textPainter.width / 2, tooltipY - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveLineChartPainter oldDelegate) {
    // Agar grafik merender ulang jika posisi sentuhan berubah
    return oldDelegate.touchX != touchX;
  }
}

// --- HALAMAN CONTROL ---
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool isPumpOn = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("Kontrol Pompa", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))), backgroundColor: Colors.white, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Mode Saat Ini: MANUAL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => setState(() => isPumpOn = !isPumpOn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: isPumpOn ? Colors.green[50] : Colors.red[50], shape: BoxShape.circle, border: Border.all(color: isPumpOn ? Colors.green : Colors.red, width: 2)),
                child: Icon(Icons.power_settings_new, size: 80, color: isPumpOn ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN HISTORY ---
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> historyData = [
      {"waktu": "16:55", "suhu": "30.25", "ppm": "58", "status": "OFF"},
      {"waktu": "16:50", "suhu": "30.25", "ppm": "58", "status": "OFF"},
      {"waktu": "16:45", "suhu": "30.20", "ppm": "58", "status": "ON"},
      {"waktu": "16:40", "suhu": "30.15", "ppm": "45", "status": "OFF"},
      {"waktu": "16:35", "suhu": "30.10", "ppm": "10", "status": "OFF"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("Riwayat Data", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))), backgroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("Suhu", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("PPM", style: TextStyle(fontWeight: FontWeight.bold))),
                Text("Pompa", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: historyData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = historyData[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item["waktu"]!, style: const TextStyle(color: Colors.grey))),
                      Expanded(child: Text("${item["suhu"]}°C", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
                      Expanded(child: Text(item["ppm"]!, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: item["status"] == "ON" ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                        child: Text(item["status"]!, style: TextStyle(fontSize: 12, color: item["status"] == "ON" ? Colors.green : Colors.grey[600], fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- HALAMAN SETTINGS ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String mode = "Manual";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: const Text("Mode Operasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ListTile(
              title: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Switch(value: mode == "Otomatis", activeColor: const Color(0xFF1A237E), onChanged: (val) => setState(() => mode = val ? "Otomatis" : "Manual")),
            ),
          ),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: const Text("Konfigurasi Nutrisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Column(
              children: [
                TextField(decoration: InputDecoration(labelText: "Standar Nutrisi (PPM Min)", suffixText: "PPM", border: UnderlineInputBorder())),
                SizedBox(height: 16),
                TextField(decoration: InputDecoration(labelText: "Smart Delay Pompa", suffixText: "Detik", border: UnderlineInputBorder())),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan Disimpan!"), backgroundColor: Colors.green)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Simpan Pengaturan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
