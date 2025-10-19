import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'wifi_scanner_screen.dart';

class HomeWifi extends StatefulWidget {
  const HomeWifi({super.key});

  @override
  State<HomeWifi> createState() => _HomeWifiState();
}

class _HomeWifiState extends State<HomeWifi> {
  bool _isScanning = false; // Bien trang thai dang quet

  void _StartScan(BuildContext context) {
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isScanning = false;
      });
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WifiScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(" Home Wifi")),
      body: Center(
        child: _isScanning
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    "assets/logo/Scan.json",
                    width: 200,
                    height: 200,
                    repeat: true,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Scanning nearby Wi-Fi networks...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            : ElevatedButton.icon(
                icon: const Icon(Icons.wifi),
                label: const Text("Start Wi-Fi Scan"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _StartScan(context),
              ),
      ),
    );
  }
}
