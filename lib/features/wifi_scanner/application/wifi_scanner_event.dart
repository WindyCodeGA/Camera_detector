part of 'wifi_scanner_bloc.dart';

abstract class WifiScannerEvent extends Equatable {
  const WifiScannerEvent();

  @override
  List<Object> get props => [];
}

// Khi người dùng nhấn nút "Start Wi-Fi Scan"
class ScanStarted extends WifiScannerEvent {}

// Yêu cầu lại quyền (nếu bị từ chối)
class PermissionRequested extends WifiScannerEvent {}

// --- Sự kiện nội bộ của BLoC ---
// Khi có kết quả quét mới từ timer
class _ScanResultsUpdated extends WifiScannerEvent {
  final List<WiFiAccessPoint> networks;
  const _ScanResultsUpdated(this.networks);

  @override
  List<Object> get props => [networks];
}

// Khi trạng thái quyền thay đổi
class _PermissionStatusChanged extends WifiScannerEvent {
  final PermissionStatus status;
  const _PermissionStatusChanged(this.status);
  @override
  List<Object> get props => [status];
}

class _ScanFailed extends WifiScannerEvent {
  final String errorMessage;
  const _ScanFailed(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
