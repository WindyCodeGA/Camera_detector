part of 'bluetooth_bloc.dart';

abstract class BluetoothScannerEvent extends Equatable {
  const BluetoothScannerEvent();
  @override
  List<Object> get props => [];
}

// Bật quét (Nút Play)
class ToggleScanEvent extends BluetoothScannerEvent {}

// Dừng ngay khi quét (Khi rời màn hình)
class StopScanEvent extends BluetoothScannerEvent {}

// Áp dụng bộ lọc
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

// --- Sự kiện nội bộ ---
class _IsScanningUpdatedEvent extends BluetoothScannerEvent {
  final bool isScanning;
  const _IsScanningUpdatedEvent(this.isScanning);
  @override
  List<Object> get props => [isScanning];
}

class _ScanResultsUpdatedEvent extends BluetoothScannerEvent {
  final List<ScanResult> results;
  const _ScanResultsUpdatedEvent(this.results);
  @override
  List<Object> get props => [results];
}

class _AdapterStateUpdatedEvent extends BluetoothScannerEvent {
  final BluetoothAdapterState adapterState;
  const _AdapterStateUpdatedEvent(this.adapterState);
  @override
  List<Object> get props => [adapterState];
}

class _UpdateChartEvent extends BluetoothScannerEvent {}
