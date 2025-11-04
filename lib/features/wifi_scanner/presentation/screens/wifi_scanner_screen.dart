import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:wifi_scan/wifi_scan.dart';

// Import BLoC của chúng ta
import '../../application/wifi_scanner_bloc.dart';

class WifiScannerScreen extends StatelessWidget {
  const WifiScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Không cần Scaffold ở đây vì nó đã được cung cấp
    // bởi HomeScreen (BottomNavigationBar)

    return BlocBuilder<WifiScannerBloc, WifiScannerState>(
      builder: (context, state) {
        // Dùng switch-case để quyết định UI
        switch (state.status) {
          case WifiScannerStatus.initial:
            return _buildStartUI(context, isLoading: false);

          case WifiScannerStatus.loading:
            return _buildStartUI(context, isLoading: true);

          case WifiScannerStatus.permissionDenied:
            return _buildPermissionDeniedUI(context);

          case WifiScannerStatus.scanning:
            return _buildScanListUI(context, state.networks);

          case WifiScannerStatus.error:
            return Center(
              child: Text(
                "Đã xảy ra lỗi: ${state.errorMessage ?? 'Không xác định'}",
              ),
            );
        }
      },
    );
  }

  // --- CÁC HÀM XÂY DỰNG UI ---

  // UI từ file `screen_wifi.dart` (cũ)
  Widget _buildStartUI(BuildContext context, {required bool isLoading}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Lottie.asset(
            'assets/scan.json',
            animate: isLoading,
            width: 200,
            height: 200,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.wifi),
          label: Text(isLoading ? "Scanning..." : "Start Wi-Fi Scan"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18),
          ),
          // Khi nhấn, gửi sự kiện ScanStarted
          onPressed: isLoading
              ? null
              : () => context.read<WifiScannerBloc>().add(ScanStarted()),
        ),
      ],
    );
  }

  // UI hiển thị danh sách Wi-Fi (từ `wifi_scanner_screen.dart` cũ)
  Widget _buildScanListUI(
    BuildContext context,
    List<WiFiAccessPoint> networks,
  ) {
    if (networks.isEmpty) {
      return const Center(child: Text("Đang tìm kiếm mạng Wi-Fi..."));
    }

    return ListView.builder(
      itemCount: networks.length,
      itemBuilder: (context, index) {
        final wifi = networks[index];
        final label = _getSignalLabel(wifi.level);
        final color = _getSignalColor(wifi.level);

        return Card(
          child: ListTile(
            title: Text(
              "SSID: ${wifi.ssid.isNotEmpty ? wifi.ssid : '(Hidden Network)'}",
            ),
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
          ),
        );
      },
    );
  }

  // UI khi bị từ chối quyền
  Widget _buildPermissionDeniedUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Quyền truy cập vị trí bị từ chối.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Vui lòng cấp quyền vị trí để quét Wi-Fi.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text("Cấp quyền"),
            onPressed: () =>
                context.read<WifiScannerBloc>().add(PermissionRequested()),
          ),
        ],
      ),
    );
  }

  // --- CÁC HÀM HELPER ---
  // (Lấy từ code cũ của bạn)

  String _getSignalLabel(int level) {
    if (level >= -50) return "Very Close";
    if (level >= -67) return "Nearby";
    if (level >= -75) return "Far";
    return "Out of Range";
  }

  Color _getSignalColor(int level) {
    if (level >= -30) return Colors.blue;
    if (level >= -40) return Colors.green;
    if (level >= -75) return Colors.orange;
    return Colors.red;
  }
}
