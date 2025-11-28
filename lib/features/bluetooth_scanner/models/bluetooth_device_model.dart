import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceModel extends Equatable {
  final ScanResult scanResult;
  final double riskScore; // 0.0 -> 100.0

  const BluetoothDeviceModel({
    required this.scanResult,
    required this.riskScore,
  });

  // Getter tiện ích để lấy tên
  String get name {
    if (scanResult.device.platformName.isNotEmpty) {
      return scanResult.device.platformName;
    } else if (scanResult.advertisementData.advName.isNotEmpty) {
      return scanResult.advertisementData.advName;
    }
    return 'Unknown Device';
  }

  @override
  List<Object> get props => [scanResult, riskScore];
}
