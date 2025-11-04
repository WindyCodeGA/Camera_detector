part of 'wifi_scanner_bloc.dart';

// Trạng thái chung của màn hình
enum WifiScannerStatus {
  initial, // Màn hình 'Start'
  loading, // Màn hình 'Start' với animation (sau khi nhấn nút)
  scanning, // Màn hình danh sách Wi-Fi
  permissionDenied, // Màn hình báo lỗi thiếu quyền
  error, // Màn hình báo lỗi chung
}

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
