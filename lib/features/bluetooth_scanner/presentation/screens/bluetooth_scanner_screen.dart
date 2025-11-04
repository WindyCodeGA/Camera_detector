import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// Import BLoC và State bằng đường dẫn tương đối
import '../../application/bluetooth_bloc.dart';

// Đổi tên class cho phù hợp với tên file
class BluetoothScannerScreen extends StatelessWidget {
  const BluetoothScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Chúng ta cung cấp BLoC ở file main.dart (hoặc ở file router)
    // nên ở đây ta chỉ cần `context.read` hoặc `BlocBuilder`
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner (BLoC)'),
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
            _showSnackbar(
              context,
              "Bluetooth đã tắt. Vui lòng bật Bluetooth.",
              Colors.orange,
            );
          } else if (state.status == ScannerStatus.error) {
            _showSnackbar(
              context,
              state.errorMessage ?? "Đã xảy ra lỗi",
              Colors.red,
            );
          }
        },
        child: Column(
          children: [_buildHeader(), _buildDeviceList(), _buildChart()],
        ),
      ),
    );
  }

  // Widget Header
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

  // Widget Danh sách
  Widget _buildDeviceList() {
    return Expanded(
      child: BlocBuilder<BluetoothScannerBloc, BluetoothScannerState>(
        buildWhen: (prev, curr) =>
            prev.filteredScanResults != curr.filteredScanResults,
        builder: (context, state) {
          if (state.filteredScanResults.isEmpty && !state.isScanning) {
            return const Center(child: Text("Không tìm thấy thiết bị nào."));
          }
          if (state.filteredScanResults.isEmpty && state.isScanning) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: state.filteredScanResults.length,
            itemBuilder: (context, index) {
              final result = state.filteredScanResults[index];
              String deviceName = result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : 'Unknown (${result.device.remoteId.str.substring(0, 6)}...)';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(
                    deviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.device.remoteId.str),
                      Text(
                        'Cường độ tín hiệu: ${result.rssi} dBm',
                        style: TextStyle(
                          color: (result.rssi > -60)
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (result.rssi > -60)
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${result.rssi}',
                      style: TextStyle(
                        color: (result.rssi > -60)
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget Biểu đồ
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
                'Devices over time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    minX: state.chartData.isNotEmpty
                        ? state.chartData.first.x
                        : 0,
                    maxX: state.chartData.isNotEmpty
                        ? state.chartData.last.x
                        : 1,
                    minY: 0,
                    maxY: state.chartData.isNotEmpty
                        ? max(
                            5,
                            state.chartData
                                    .map((e) => e.y)
                                    .reduce(max)
                                    .toDouble() *
                                1.2,
                          )
                        : 5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm hiển thị Bottom Sheet
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Min RSSI Slider
                    Row(
                      children: [
                        const Text('Min RSSI (dBm):'),
                        Expanded(
                          child: Slider(
                            value: tempMinRssi,
                            min: -100.0,
                            max: 0.0,
                            divisions: 100,
                            label: tempMinRssi.toStringAsFixed(0),
                            onChanged: (double newValue) {
                              setModalState(() {
                                tempMinRssi = newValue;
                              });
                            },
                          ),
                        ),
                        Text(tempMinRssi.toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Only named devices switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Only named devices'),
                        Switch(
                          value: tempOnlyNamed,
                          onChanged: (bool newValue) {
                            setModalState(() {
                              tempOnlyNamed = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Only connectable devices switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Only connectable devices'),
                        Switch(
                          value: tempOnlyConnectable,
                          onChanged: (bool newValue) {
                            setModalState(() {
                              tempOnlyConnectable = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút Apply / Cancel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.pop(bc);
                          },
                        ),
                        ElevatedButton(
                          child: const Text('Apply'),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Hàm hiển thị Snackbar (tiện ích)
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
