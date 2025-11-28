import 'package:flutter/material.dart';

//
// --- CẬP NHẬT IMPORT ---
// Tất cả các màn hình bây giờ được import từ đường dẫn 'features' mới
//

// Import BLoC screen của chúng ta
import 'package:camera_detector/features/bluetooth_scanner/presentation/screens/bluetooth_scanner_screen.dart';
import 'package:camera_detector/features/wifi_scanner/presentation/screens/wifi_scanner_screen.dart';
import 'package:camera_detector/features/ir_scanner/presentation/screens/ir_scanner_screen.dart';
import 'package:camera_detector/features/magnetic_field/presentation/screens/magnetic_field_scanner_screen.dart';
import 'package:camera_detector/features/history/presentation/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình cho BottomNavBar
  final List<Widget> _screens = [
    const IRScannerScreen(),
    const WifiScannerScreen(),
    const BluetoothScannerScreen(),
    const MagneticFieldScannerScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'IR Scanner',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'WiFi'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Magnetic'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
