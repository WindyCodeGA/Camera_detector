part of 'bluetooth_bloc.dart'; // part of để liên kết với file BLoC

// Lớp cơ sở cho tất cả các sự kiện
abstract class BluetoothScannerEvent extends Equatable {
  const BluetoothScannerEvent();

  @override
  List<Object> get props => [];
}

// Sự kiện khi người dùng nhấn nút play/stop
class ToggleScanEvent extends BluetoothScannerEvent {}

// Sự kiện khi người dùng nhấn "Apply" trong bộ lọc
class ApplyFiltersEvent extends BluetoothScannerEvent {
  final double minRssi;
  final bool onlyNamedDevices;
  final bool onlyConnectableDevices;

  const ApplyFiltersEvent({
    required this.minRssi,
    required this.onlyNamedDevices,
    required this.onlyConnectableDevices,
  });

  @override
  List<Object> get props => [minRssi, onlyNamedDevices, onlyConnectableDevices];
}

// --- Các sự kiện nội bộ BLoC (UI không gọi) ---

// Sự kiện khi trạng thái quét (isScanning) thay đổi
class _IsScanningUpdatedEvent extends BluetoothScannerEvent {
  final bool isScanning;
  const _IsScanningUpdatedEvent(this.isScanning);

  @override
  List<Object> get props => [isScanning];
}

// Sự kiện khi có kết quả quét mới
class _ScanResultsUpdatedEvent extends BluetoothScannerEvent {
  final List<ScanResult> results;
  const _ScanResultsUpdatedEvent(this.results);

  @override
  List<Object> get props => [results];
}

// Sự kiện khi trạng thái adapter (on/off) thay đổi
class _AdapterStateUpdatedEvent extends BluetoothScannerEvent {
  final BluetoothAdapterState adapterState;
  const _AdapterStateUpdatedEvent(this.adapterState);

  @override
  List<Object> get props => [adapterState];
}

// Sự kiện từ Timer để cập nhật biểu đồ
class _UpdateChartEvent extends BluetoothScannerEvent {}
