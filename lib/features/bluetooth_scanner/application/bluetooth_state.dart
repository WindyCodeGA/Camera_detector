part of 'bluetooth_bloc.dart';

enum ScannerStatus { initial, scanning, stopped, adapterOff, error }

class BluetoothScannerState extends Equatable {
  final ScannerStatus status;
  final bool isScanning;
  final String? errorMessage;

  // Bộ lọc
  final double minRssiFilter;
  final bool onlyNamedDevices;
  final bool onlyConnectableDevices;

  // Dữ liệu kết quả (Model Mới)
  final List<BluetoothDeviceModel> allScanResults;
  final List<BluetoothDeviceModel> filteredScanResults;
  final double avgRssi;

  // Biểu đồ
  final List<FlSpot> chartData;
  final int chartXValue;

  const BluetoothScannerState({
    required this.status,
    required this.isScanning,
    this.errorMessage,
    required this.minRssiFilter,
    required this.onlyNamedDevices,
    required this.onlyConnectableDevices,
    required this.allScanResults,
    required this.filteredScanResults,
    required this.avgRssi,
    required this.chartData,
    required this.chartXValue,
  });

  factory BluetoothScannerState.initial() {
    return const BluetoothScannerState(
      status: ScannerStatus.initial,
      isScanning: false,
      minRssiFilter: -100.0,
      onlyNamedDevices: false,
      onlyConnectableDevices: false,
      allScanResults: [],
      filteredScanResults: [],
      avgRssi: 0.0,
      chartData: [],
      chartXValue: 0,
    );
  }

  BluetoothScannerState copyWith({
    ScannerStatus? status,
    bool? isScanning,
    String? errorMessage,
    double? minRssiFilter,
    bool? onlyNamedDevices,
    bool? onlyConnectableDevices,
    List<BluetoothDeviceModel>? allScanResults,
    List<BluetoothDeviceModel>? filteredScanResults,
    double? avgRssi,
    List<FlSpot>? chartData,
    int? chartXValue,
  }) {
    return BluetoothScannerState(
      status: status ?? this.status,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage ?? this.errorMessage,
      minRssiFilter: minRssiFilter ?? this.minRssiFilter,
      onlyNamedDevices: onlyNamedDevices ?? this.onlyNamedDevices,
      onlyConnectableDevices:
          onlyConnectableDevices ?? this.onlyConnectableDevices,
      allScanResults: allScanResults ?? this.allScanResults,
      filteredScanResults: filteredScanResults ?? this.filteredScanResults,
      avgRssi: avgRssi ?? this.avgRssi,
      chartData: chartData ?? this.chartData,
      chartXValue: chartXValue ?? this.chartXValue,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isScanning,
    errorMessage,
    minRssiFilter,
    onlyNamedDevices,
    onlyConnectableDevices,
    allScanResults,
    filteredScanResults,
    avgRssi,
    chartData,
    chartXValue,
  ];
}
