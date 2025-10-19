import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  List<WiFiAccessPoint> _wifiNetworks = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startRealtimeScan();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cần quyền Location để quét Wi-Fi")),
      );
    }
  }

  void _startRealtimeScan() {
    // Quét lại mỗi 2 giây
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _scanWifi());
  }

  Future<void> _scanWifi() async {
    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();

    setState(() {
      _wifiNetworks = results;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Trả về nhãn tín hiệu
  String getSignalLabel(int level) {
    if (level >= -50) return "Very Close";
    if (level >= -67) return "Nearby";
    if (level >= -75) return "Far";
    if (level >= -85) return "Out of Range";
    return "Rất yếu";
  }

  /// Trả về màu dựa trên mức tín hiệu
  Color getSignalColor(int level) {
    if (level >= -30) return Colors.blue;
    if (level >= -40) return Colors.green; // Rất mạnh & Mạnh
    if (level >= -75) return Colors.orange; // Trung bình
    return Colors.red; // Yếu & Rất yếu
  }

  /// Trả về icon Wi-Fi dựa vào mức tín hiệu
  // IconData getSignalIcon(int level) {
  //   if (level >= -50) return Icons.signal_wifi_4_bar; // Rất mạnh
  //   if (level >= -67) return Icons.signal_wifi_0_bar; // Mạnh
  //   if (level >= -75) return Icons.signal_wifi_0_bar; // Trung bình
  //   if (level >= -85) return Icons.signal_wifi_0_bar; // Yếu
  //   return Icons.signal_wifi_bad; // Rất yếu
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wi-Fi Scanner")),
      body: ListView.builder(
        itemCount: _wifiNetworks.length,
        itemBuilder: (context, index) {
          final wifi = _wifiNetworks[index];
          final label = getSignalLabel(wifi.level);
          final color = getSignalColor(wifi.level);
          // final icon = getSignalIcon(wifi.level);

          return Card(
            child: ListTile(
              title: Text("SSID: ${wifi.ssid}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BSSID: ${wifi.bssid}"),
                  Text(
                    "Mức tín hiệu: ${wifi.level} dBm ($label)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              // trailing: Icon(icon, color: color, size: 30),
            ),
          );
        },
      ),
    );
  }
}
