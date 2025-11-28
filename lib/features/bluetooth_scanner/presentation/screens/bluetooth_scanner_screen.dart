import 'dart:math'; // Đã được dùng (hàm max cho biểu đồ)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart'; // Đã được dùng (LineChart)
// Đã được dùng (ScannerStatus)

// Import BLoC, State và Model
import '../../application/bluetooth_bloc.dart';
import '../../models/bluetooth_device_model.dart'; // Đã được dùng (BluetoothDeviceModel)
import 'device_tracker_screen.dart'; // Đã được dùng (Navigator push)

class BluetoothScannerScreen extends StatefulWidget {
  const BluetoothScannerScreen({super.key});

  @override
  State<BluetoothScannerScreen> createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Bật quét khi vào màn hình
    context.read<BluetoothScannerBloc>().add(ToggleScanEvent());
  }

  @override
  void dispose() {
    // Dừng quét khi rời đi để tránh lag
    context.read<BluetoothScannerBloc>().add(StopScanEvent());
    super.dispose();
  }

  // Helper: Chọn màu dựa trên mức độ rủi ro
  Color _getRiskColor(double score) {
    if (score >= 70) return Colors.red.shade700;
    if (score >= 40) return Colors.orange.shade700;
    if (score >= 20) return Colors.yellow.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Detector'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          BlocBuilder<BluetoothScannerBloc, BluetoothScannerState>(
            buildWhen: (prev, curr) => prev.isScanning != curr.isScanning,
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.isScanning ? Icons.stop : Icons.play_arrow),
                onPressed: () {
                  context.read<BluetoothScannerBloc>().add(ToggleScanEvent());
                },
              );
            },
          ),
        ],
      ),
      body: BlocListener<BluetoothScannerBloc, BluetoothScannerState>(
        listener: (context, state) {
          if (state.status == ScannerStatus.adapterOff) {
            _showSnackbar(context, "Bluetooth đã tắt.", Colors.orange);
          } else if (state.status == ScannerStatus.error) {
            _showSnackbar(context, state.errorMessage ?? "Lỗi", Colors.red);
          }
        },
        child: Column(
          children: [
            _buildHeader(),
            _buildDeviceList(), // Hàm này dùng BluetoothDeviceModel và DeviceTrackerScreen
            _buildChart(), // Hàm này dùng dart:math và fl_chart
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<BluetoothScannerBloc, BluetoothScannerState>(
      buildWhen: (prev, curr) =>
          prev.filteredScanResults.length != curr.filteredScanResults.length ||
          prev.avgRssi != curr.avgRssi,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Chip(
                label: Text('Thiết bị: ${state.filteredScanResults.length}'),
                backgroundColor: Colors.blue.shade100,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  'Avg RSSI: ${state.avgRssi.toStringAsFixed(1)} dBm',
                ),
                backgroundColor: Colors.green.shade100,
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget hiển thị danh sách thiết bị
  Widget _buildDeviceList() {
    return Expanded(
      child: BlocBuilder<BluetoothScannerBloc, BluetoothScannerState>(
        buildWhen: (prev, curr) =>
            prev.filteredScanResults != curr.filteredScanResults,
        builder: (context, state) {
          if (state.filteredScanResults.isEmpty && !state.isScanning) {
            return const Center(child: Text("Sẵn sàng quét..."));
          }
          if (state.filteredScanResults.isEmpty && state.isScanning) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: state.filteredScanResults.length,
            itemBuilder: (context, index) {
              // --- FIX LỖI UNUSED IMPORT MODEL ---
              // Lấy dữ liệu từ Model
              final BluetoothDeviceModel model =
                  state.filteredScanResults[index];
              final result = model.scanResult;
              final risk = model.riskScore;

              final riskColor = _getRiskColor(risk);

              return Card(
                elevation: risk > 50 ? 4 : 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                // Viền đỏ nếu rủi ro cao
                shape: risk > 50
                    ? RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ListTile(
                  // --- FIX LỖI UNUSED IMPORT SCREEN ---
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeviceTrackerScreen(deviceModel: model),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: riskColor.withValues(
                      alpha: 0.2,
                    ), // Fix withOpacity
                    child: Icon(Icons.bluetooth, color: riskColor),
                  ),
                  title: Text(
                    model.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${result.device.remoteId.str}"),
                      Row(
                        children: [
                          Text(
                            '${result.rssi} dBm',
                            style: TextStyle(
                              color: (result.rssi > -60)
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Rủi ro: ${risk.toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget Biểu đồ (Sử dụng fl_chart và dart:math)
  Widget _buildChart() {
    return BlocBuilder<BluetoothScannerBloc, BluetoothScannerState>(
      buildWhen: (prev, curr) => prev.chartData != curr.chartData,
      builder: (context, state) {
        return Container(
          height: 180,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mật độ thiết bị',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: state.chartData,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    minY: 0,
                    // --- FIX LỖI UNUSED IMPORT dart:math ---
                    // Sử dụng hàm max()
                    maxY: state.chartData.isNotEmpty
                        ? max(
                            5.0,
                            state.chartData
                                    .map((e) => e.y)
                                    .reduce(max)
                                    .toDouble() *
                                1.2,
                          )
                        : 5.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final currentState = context.read<BluetoothScannerBloc>().state;
    double tempMinRssi = currentState.minRssiFilter;
    bool tempOnlyNamed = currentState.onlyNamedDevices;
    bool tempOnlyConnectable = currentState.onlyConnectableDevices;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bc).viewInsets.bottom,
                top: 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Min RSSI:'),
                        Expanded(
                          child: Slider(
                            value: tempMinRssi,
                            min: -100,
                            max: 0,
                            divisions: 100,
                            label: tempMinRssi.toStringAsFixed(0),
                            onChanged: (v) =>
                                setModalState(() => tempMinRssi = v),
                          ),
                        ),
                        Text(tempMinRssi.toStringAsFixed(0)),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Chỉ thiết bị có tên'),
                      value: tempOnlyNamed,
                      onChanged: (v) => setModalState(() => tempOnlyNamed = v),
                    ),
                    SwitchListTile(
                      title: const Text('Chỉ thiết bị kết nối được'),
                      value: tempOnlyConnectable,
                      onChanged: (v) =>
                          setModalState(() => tempOnlyConnectable = v),
                    ),
                    ElevatedButton(
                      child: const Text('Áp dụng'),
                      onPressed: () {
                        context.read<BluetoothScannerBloc>().add(
                          ApplyFiltersEvent(
                            minRssi: tempMinRssi,
                            onlyNamedDevices: tempOnlyNamed,
                            onlyConnectableDevices: tempOnlyConnectable,
                          ),
                        );
                        Navigator.pop(bc);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
