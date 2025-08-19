import 'package:flutter/material.dart';
import 'wifi_scanner_screen.dart';
import 'bluetooth_scanner_screen.dart';
import 'ir_scanner_screen.dart';
import 'flashlight_screen.dart';
import 'magnetic_field_scanner_screen.dart';
import '../widgets/scan_option_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ScanOptionsScreen(),
    const WifiScannerScreen(),
    const BluetoothScannerScreen(),
    const MagneticFieldScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'WiFi'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Magnetic'),
        ],
      ),
    );
  }
}

class ScanOptionsScreen extends StatelessWidget {
  const ScanOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Detection Method',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                ScanOptionCard(
                  title: 'WiFi Scanner',
                  icon: Icons.wifi,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WifiScannerScreen(),
                      ),
                    );
                  },
                ),
                ScanOptionCard(
                  title: 'Bluetooth Scanner',
                  icon: Icons.bluetooth,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BluetoothScannerScreen(),
                      ),
                    );
                  },
                ),
                ScanOptionCard(
                  title: 'IR Scanner',
                  icon: Icons.sensors,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IRScannerScreen(),
                      ),
                    );
                  },
                ),
                ScanOptionCard(
                  title: 'Camera Detection',
                  icon: Icons.flashlight_on,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlashlightScreen(),
                      ),
                    );
                  },
                ),
                ScanOptionCard(
                  title: 'Magnetic Field',
                  icon: Icons.explore,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MagneticFieldScannerScreen(),
                      ),
                    );
                  },
                ),
                ScanOptionCard(
                  title: 'Settings',
                  icon: Icons.settings,
                  onTap: () {
                    // Navigate to Settings
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
