import 'package:flutter/material.dart';

class BluetoothScannerScreen extends StatefulWidget {
  const BluetoothScannerScreen({super.key});

  @override
  State<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  List<Map<String, dynamic>> _devices = [];
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
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    // Simulate Bluetooth scanning
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _devices = [
        {'name': 'iPhone 13', 'address': '00:11:22:33:44:55', 'rssi': -65},
        {'name': 'Samsung Galaxy', 'address': '66:77:88:99:AA:BB', 'rssi': -72},
        {'name': 'AirPods Pro', 'address': 'CC:DD:EE:FF:00:11', 'rssi': -45},
        {'name': 'Unknown Device', 'address': 'AA:BB:CC:DD:EE:FF', 'rssi': -80},
        {'name': 'Smart Watch', 'address': '11:22:33:44:55:66', 'rssi': -55},
      ];
      _isScanning = false;
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
      appBar: AppBar(title: const Text('Bluetooth Scanner')),
      body: Column(
        children: [
          // Scan button area
          Expanded(
            flex: 2,
            child: Center(
              child: AnimatedBuilder(
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
                            color: Theme.of(context).primaryColor.withAlpha(
                              (0.3 * 255).round(),
                            ), //là điều chỉnh độ trong suốt của một màu thành 30% một cách chính xác bằng cách sử dụng giá trị alpha. để thay thế cho with Opacity
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isScanning ? null : _startScan,
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
            ),
          ),

          // Results area
          Expanded(
            flex: 3,
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? 'Scanning for devices...'
                          : 'Tap scan to find Bluetooth devices',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Found ${_devices.length} devices',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.bluetooth,
                                  color: Colors.blue,
                                ),
                                title: Text(device['name']),
                                subtitle: Text(device['address']),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRSSIColor(device['rssi']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${device['rssi']} dBm',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRSSIColor(int rssi) {
    if (rssi > -50) return Colors.green;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
  }
}
