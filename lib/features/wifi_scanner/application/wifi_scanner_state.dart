part of 'wifi_scanner_bloc.dart';

// Trạng thái chung của màn hình
enum WifiScannerStatus { initial, loading, scanning, permissionDenied, error }

class WifiScannerState extends Equatable {
  final WifiScannerStatus status;
  final List<WiFiAccessPoint> networks; // Danh sách Wi-Fi tìm thấy
  final String? errorMessage;

  const WifiScannerState({
    required this.status,
    required this.networks,
    this.errorMessage,
  });

  // Trạng thái khởi tạo
  factory WifiScannerState.initial() {
    return const WifiScannerState(
      status: WifiScannerStatus.initial,
      networks: [],
    );
  }

  // Hàm copyWith
  WifiScannerState copyWith({
    WifiScannerStatus? status,
    List<WiFiAccessPoint>? networks,
    String? errorMessage,
  }) {
    return WifiScannerState(
      status: status ?? this.status,
      networks: networks ?? this.networks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, networks, errorMessage];
}
