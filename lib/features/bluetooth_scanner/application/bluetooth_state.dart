part of 'bluetooth_bloc.dart'; // part of để liên kết với file BLoC

// Enum để thể hiện trạng thái chung
enum ScannerStatus { initial, scanning, stopped, adapterOff, error }

class BluetoothScannerState extends Equatable {
  // Trạng thái chung
  final ScannerStatus status;
  final bool isScanning; // Trùng lặp với status nhưng tiện lợi
  final String? errorMessage; // Thông báo lỗi nếu có

  // Dữ liệu bộ lọc
  final double minRssiFilter;
  final bool onlyNamedDevices;
  final bool onlyConnectableDevices;

  // Dữ liệu kết quả
  final List<ScanResult> allScanResults; // Danh sách thô
  final List<ScanResult> filteredScanResults; // Danh sách đã lọc
  final double avgRssi;

  // Dữ liệu biểu đồ
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

  // Trạng thái khởi tạo
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

  // Hàm copyWith để tạo trạng thái mới dựa trên trạng thái cũ
  BluetoothScannerState copyWith({
    ScannerStatus? status,
    bool? isScanning,
    String? errorMessage,
    double? minRssiFilter,
    bool? onlyNamedDevices,
    bool? onlyConnectableDevices,
    List<ScanResult>? allScanResults,
    List<ScanResult>? filteredScanResults,
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
