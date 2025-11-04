import 'package:flutter/material.dart';

//
// --- CẬP NHẬT IMPORT ---
// Tất cả các màn hình bây giờ được import từ đường dẫn 'features' mới
//

// Import BLoC screen của chúng ta
import 'package:camera_detector/features/bluetooth_scanner/presentation/screens/bluetooth_scanner_screen.dart';
import 'package:camera_detector/features/wifi_scanner/presentation/screens/wifi_scanner_screen.dart';

// Import cho phần code GridView (đang bị comment)
// import 'package:camera_detector/features/flashlight/presentation/screens/flashlight_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình cho BottomNavBar
  final List<Widget> _screens = [
    // const IRScannerScreen(),
    const WifiScannerScreen(),
    const BluetoothScannerScreen(),
    // const MagneticFieldScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        ],
      ),
    );
  }
}


//
// --- PHẦN CODE COMMENT CŨ ---
// Tôi vẫn giữ lại phần code này và cũng đã cập nhật các đường dẫn
// import và class name cho nó, phòng trường hợp bạn muốn dùng lại.
//

// class ScanOptionsScreen extends StatelessWidget {
//   const ScanOptionsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Select Detection Method',
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 ScanOptionCard(
//                   title: 'WiFi Scanner',
//                   icon: Icons.wifi,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const HomeWifi()), // Đã thêm const
//                     );
//                   },
//                 ),
//                 ScanOptionCard(
//                   title: 'Bluetooth Scanner',
//                   icon: Icons.bluetooth,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         // Đã đúng, dùng BLoC screen
//                         builder: (context) => const BluetoothScannerScreen(), 
//                       ),
//                     );
//                   },
//                 ),
//                 ScanOptionCard(
//                   title: 'IR Scanner',
//                   icon: Icons.sensors,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const IRScannerScreen(),
//                       ),
//                     );
//                   },
//                 ),
//                 // ScanOptionCard(
//                 //   title: 'Camera Detection',
//                 //   icon: Icons.flashlight_on,
//                 //   onTap: () {
//                 //     Navigator.push(
//                 //       context,
//                 //       MaterialPageRoute(
//                 //         builder: (context) => const FlashlightScreen(), // Cần import file này
//                 //       ),
//                 //     );
//                 //   },
//                 // ),
//                 ScanOptionCard(
//                   title: 'Magnetic Field',
//                   icon: Icons.explore,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) =>
//                             const MagneticFieldScannerScreen(),
//                       ),
//                     );
//                   },
//                 ),
//                 ScanOptionCard(
//                   title: 'Settings',
//                   icon: Icons.settings,
//                   onTap: () {
//                     // Navigate to Settings
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }