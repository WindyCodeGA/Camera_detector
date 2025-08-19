import 'package:flutter/material.dart';
import '../models/network_device.dart';
import '../services/wifi_scanner_service.dart';
import 'device_details_screen.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen>
    with SingleTickerProviderStateMixin {
  final WifiScannerService _scannerService = WifiScannerService();
  List<NetworkDevice> _devices = [];
  bool _isScanning = false;
  String _connectedNetwork = '';
  String _ipAddress = '';
  int _suspiciousDevicesCount = 0;
  bool _hasScanned = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeWifiInfo();
  }

  Future<void> _initializeWifiInfo() async {
    setState(() {
      _connectedNetwork = "Home_WiFi_Network";
      _ipAddress = "192.168.1.4";
    });
  }

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
      _hasScanned = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    final devices = await _scannerService.scanDevices();
    setState(() {
      _devices = devices;
      _suspiciousDevicesCount = devices
          .where((device) => device.isSuspicious)
          .length;
      _isScanning = false;
      _hasScanned = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Scanner')),
      body: Column(
        children: [
          // Network info section
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Connected to: "$_connectedNetwork"',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'IP address: $_ipAddress',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Scan button and visualization area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid background
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 300),
                  painter: GridPainter(),
                ),

                // Scan button
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isScanning ? _animation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha((0.3 * 255).round()),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isScanning ? null : _scanNetwork,
                            borderRadius: BorderRadius.circular(60),
                            child: Center(
                              child: Text(
                                _isScanning ? 'Scanning...' : 'Scan',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Red dots for suspicious devices
                if (_hasScanned && _suspiciousDevicesCount > 0)
                  Positioned(
                    top: 100,
                    left: 80,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (_hasScanned && _suspiciousDevicesCount > 1)
                  Positioned(
                    top: 150,
                    right: 100,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results section
          if (_hasScanned)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Suspicious devices found: $_suspiciousDevicesCount',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // View Device button
          if (_hasScanned)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeviceDetailsScreen(devices: _devices),
                      ),
                    );
                  },
                  child: const Text(
                    'View Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha((0.2 * 255).round())
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i < 10; i++) {
      final y = i * (size.height / 10);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (int i = 0; i < 10; i++) {
      final x = i * (size.width / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
