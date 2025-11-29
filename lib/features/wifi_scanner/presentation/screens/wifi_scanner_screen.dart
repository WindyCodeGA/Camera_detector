import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'network_devices_screen.dart';

import '../../application/wifi_scanner_bloc.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    context.read<WifiScannerBloc>().add(ScanStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Scanner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WifiScannerBloc>().add(ScanStarted());
            },
          ),
        ],
      ),
      body: BlocBuilder<WifiScannerBloc, WifiScannerState>(
        builder: (context, state) {
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
                      "Error: ${state.errorMessage ?? 'Not determined'}",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<WifiScannerBloc>().add(ScanStarted()),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

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
      return const Center(child: Text("Searching for Wi-Fi networks..."));
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
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),

            onTap: () async {
              final info = NetworkInfo();
              String? currentBSSID = await info.getWifiBSSID();

              if (!context.mounted) return;

              // So sánh BSSID (địa chỉ MAC của router)
              bool isConnected =
                  currentBSSID != null &&
                  wifi.bssid.toLowerCase() == currentBSSID.toLowerCase();

              // Fallback: So sánh tên SSID nếu BSSID bị ẩn
              if (!isConnected) {
                String? currentSSID = await info.getWifiName();
                String targetSSID = wifi.ssid;
                if (currentSSID != null) {
                  currentSSID = currentSSID.replaceAll('"', '');
                  if (currentSSID == targetSSID) isConnected = true;
                }
              }
              if (!context.mounted) return;
              if (isConnected) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NetworkDevicesScreen(ssid: wifi.ssid),
                  ),
                );
              } else {
                // Thông báo lỗi
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Please connect to the network '${wifi.ssid}' to scan the device!",
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
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
            "Location access denied.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Location permission is required for Wi-Fi scanning (.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text("Grant permissions"),
            onPressed: () =>
                context.read<WifiScannerBloc>().add(PermissionRequested()),
          ),
        ],
      ),
    );
  }

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
