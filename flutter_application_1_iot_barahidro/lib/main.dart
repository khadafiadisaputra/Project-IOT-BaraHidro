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

// --- DASHBOARD PAGE ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder<DeviceData>(
        future: _deviceData,
        builder: (context, snapshot) {
          final data = snapshot.hasData ? snapshot.data! : DeviceData(temperature: 30.25, ppm: 58, pumpStatus: 'off');
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Row(children: [
                Expanded(child: _buildInfoCard("Suhu Air", "${data.temperature}°C", Icons.thermostat, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildInfoCard("Nutrisi", "${data.ppm} PPM", Icons.opacity, Colors.blue)),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard("Status Pompa", data.pumpStatus.toUpperCase(), Icons.power, data.pumpStatus == 'on' ? Colors.green : Colors.red),
              const SizedBox(height: 16),
              InteractiveChartCard(title: "Grafik Suhu Realtime (°C)", icon: Icons.show_chart, color: Colors.orange, dataPoints: suhuData, isInt: false),
              const SizedBox(height: 16),
              InteractiveChartCard(title: "Grafik PPM Realtime", icon: Icons.bar_chart, color: Colors.blue, dataPoints: ppmData, isInt: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)), Icon(icon, color: color, size: 20)]),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// --- CONTROL PAGE ---
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)]),
            child: Column(children: [
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
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _buildButton("ON", true), const SizedBox(width: 20), _buildButton("OFF", false),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildButton(String label, bool status) {
    bool active = isPumpOn == status;
    return ElevatedButton(
      onPressed: () => setState(() => isPumpOn = status),
      style: ElevatedButton.styleFrom(backgroundColor: active ? (status ? Colors.green : Colors.red) : Colors.white, foregroundColor: active ? Colors.white : Colors.grey, minimumSize: const Size(100, 45)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// --- HISTORY PAGE (DENGAN FILTER) ---
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Value default dan list filter sudah diedit tanpa kata "Per"
  String selectedFilter = "Jam";
  final List<String> filters = ["Jam", "Hari", "Minggu", "Bulan"];

  // Simulasi data yang berubah berdasarkan filter
  List<Map<String, String>> _getFilteredData() {
    if (selectedFilter == "Jam") {
      return [
        {"waktu": "19:00", "suhu": "30.2", "ppm": "58"},
        {"waktu": "18:00", "suhu": "30.1", "ppm": "55"},
        {"waktu": "17:00", "suhu": "29.9", "ppm": "52"},
      ];
    } else if (selectedFilter == "Hari") {
      return [
        {"waktu": "09 Mei", "suhu": "30.1", "ppm": "56"},
        {"waktu": "08 Mei", "suhu": "29.8", "ppm": "54"},
        {"waktu": "07 Mei", "suhu": "30.3", "ppm": "57"},
      ];
    } else {
      return [
        {"waktu": "Data Terlampir", "suhu": "--", "ppm": "--"},
      ];
    }
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Mengekspor data $selectedFilter ke CSV..."),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final historyData = _getFilteredData();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Riwayat", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _exportCSV, icon: const Icon(Icons.file_download, color: Color(0xFF1A237E))),
        ],
      ),
      body: Column(children: [
        // FILTER HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Filter Tampilan:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
              DropdownButton<String>(
                value: selectedFilter,
                underline: const SizedBox(),
                items: filters.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))));
                }).toList(),
                onChanged: (newValue) => setState(() => selectedFilter = newValue!),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // TABEL HEADER
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(children: const [
            Expanded(child: Text("Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text("Suhu", style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text("Nutrisi", style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ),
        const Divider(height: 1),
        // LIST DATA
        Expanded(
          child: ListView.separated(
            itemCount: historyData.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(children: [
                Expanded(child: Text(historyData[i]["waktu"]!, style: const TextStyle(color: Colors.grey))),
                Expanded(child: Text("${historyData[i]["suhu"]}°C", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                Expanded(child: Text("${historyData[i]["ppm"]} PPM", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// --- SETTINGS PAGE ---
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
          const Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text("Mode Operasi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ListTile(
              title: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Switch(value: mode == "Otomatis", activeColor: const Color(0xFF1A237E), onChanged: (val) => setState(() => mode = val ? "Otomatis" : "Manual")),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text("Konfigurasi Nutrisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
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

// --- INTERACTIVE CHART COMPONENT ---
class InteractiveChartCard extends StatefulWidget {
  final String title; final IconData icon; final Color color; final List<double> dataPoints; final bool isInt;
  const InteractiveChartCard({super.key, required this.title, required this.icon, required this.color, required this.dataPoints, required this.isInt});
  @override State<InteractiveChartCard> createState() => _InteractiveChartCardState();
}

class _InteractiveChartCardState extends State<InteractiveChartCard> {
  double? _touchX;
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(widget.icon, color: widget.color, size: 18), const SizedBox(width: 8), Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20),
        GestureDetector(
          onPanUpdate: (d) => setState(() => _touchX = d.localPosition.dx),
          onPanDown: (d) => setState(() => _touchX = d.localPosition.dx),
          onPanEnd: (_) => setState(() => _touchX = null),
          child: SizedBox(height: 120, width: double.infinity, child: CustomPaint(painter: FullInteractivePainter(widget.dataPoints, widget.color, isInt: widget.isInt, touchX: _touchX))),
        ),
      ]),
    );
  }
}

class FullInteractivePainter extends CustomPainter {
  final List<double> data; final Color color; final bool isInt; final double? touchX;
  FullInteractivePainter(this.data, this.color, {this.isInt = false, this.touchX});

  @override void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    double maxV = data.reduce((a, b) => a > b ? a : b);
    double minV = data.reduce((a, b) => a < b ? a : b);
    if (maxV == minV) { maxV += 1; minV -= 1; }
    double range = maxV - minV;
    double pad = 35.0; double w = size.width - pad; double step = w / (data.length - 1);

    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.15)..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      double y = size.height * (i / 2);
      double val = maxV - (range * (i / 2));
      canvas.drawLine(Offset(pad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(text: TextSpan(text: isInt ? val.toInt().toString() : val.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    final path = Path(); final fillPath = Path();
    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      double x = pad + (i * step);
      double y = size.height - ((data[i] - minV) / range * size.height);
      pts.add(Offset(x, y));
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo(size.width, size.height); fillPath.close();
    canvas.drawPath(fillPath, Paint()..style = PaintingStyle.fill..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, size.height), [color.withOpacity(0.2), color.withOpacity(0)]));
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    if (touchX != null && touchX! >= pad) {
      int idx = ((touchX! - pad) / step).round().clamp(0, data.length - 1);
      Offset p = pts[idx];
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), gridPaint..color = color.withOpacity(0.5));
      canvas.drawCircle(p, 6, Paint()..color = color);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);

      final tp = TextPainter(text: TextSpan(text: isInt ? data[idx].toInt().toString() : data[idx].toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      double tx = p.dx - (tp.width / 2) - 8; double ty = p.dy - 35;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tx, ty, tp.width + 16, 24), const Radius.circular(6)), Paint()..color = Colors.black87);
      tp.paint(canvas, Offset(tx + 8, ty + 4));
    }
  }
  @override bool shouldRepaint(covariant FullInteractivePainter old) => old.touchX != touchX;
}
