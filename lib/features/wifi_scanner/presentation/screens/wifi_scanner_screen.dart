import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:wifi_scan/wifi_scan.dart';

// Import BLoC của chúng ta
import '../../application/wifi_scanner_bloc.dart';

// SỬA: Chuyển thành StatefulWidget để quản lý vòng đời
class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  @override
  void initState() {
    super.initState();
    // TỰ ĐỘNG BẮT ĐẦU QUÉT KHI VÀO MÀN HÌNH
    context.read<WifiScannerBloc>().add(ScanStarted());
  }

  @override
  void dispose() {
    // QUAN TRỌNG: DỪNG QUÉT NGAY KHI RỜI ĐI
    // Để giải phóng tài nguyên cho tab khác (Camera/Bluetooth)
    context.read<WifiScannerBloc>().add(ScanStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm Scaffold nếu chưa có (tuỳ chọn, để an toàn)
      appBar: AppBar(
        title: const Text('Wi-Fi Scanner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Nút reload thủ công
              context.read<WifiScannerBloc>().add(ScanStarted());
            },
          ),
        ],
      ),
      body: BlocBuilder<WifiScannerBloc, WifiScannerState>(
        builder: (context, state) {
          switch (state.status) {
            case WifiScannerStatus.initial:
              // Dù auto-start, vẫn giữ UI này phòng trường hợp cần thiết
              return _buildStartUI(context, isLoading: false);

            case WifiScannerStatus.loading:
              return _buildStartUI(context, isLoading: true);

            case WifiScannerStatus.permissionDenied:
              return _buildPermissionDeniedUI(context);

            case WifiScannerStatus.scanning:
              return _buildScanListUI(context, state.networks);

            case WifiScannerStatus.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Lỗi: ${state.errorMessage ?? 'Không xác định'}",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<WifiScannerBloc>().add(ScanStarted()),
                      child: const Text("Thử lại"),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  // --- CÁC HÀM XÂY DỰNG UI (GIỮ NGUYÊN) ---

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
        // Vẫn giữ nút này nhưng thực tế nó sẽ tự chạy ở initState
        ElevatedButton.icon(
          icon: const Icon(Icons.wifi),
          label: Text(isLoading ? "Scanning..." : "Start Wi-Fi Scan"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: isLoading
              ? null
              : () => context.read<WifiScannerBloc>().add(ScanStarted()),
        ),
      ],
    );
  }

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
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(Icons.wifi, color: color),
            title: Text(
              wifi.ssid.isNotEmpty ? wifi.ssid : '(Hidden Network)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("BSSID: ${wifi.bssid}"),
                Text(
                  "${wifi.level} dBm ($label)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            "Cần quyền vị trí để quét Wi-Fi (Yêu cầu của Android).",
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
