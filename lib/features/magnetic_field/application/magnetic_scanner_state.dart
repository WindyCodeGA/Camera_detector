part of 'magnetic_scanner_bloc.dart';

enum MagneticScannerStatus { initial, scanning, error }

class MagneticScannerState extends Equatable {
  final MagneticScannerStatus status;
  final double rawValue; // Giá trị thô từ cảm biến
  final double baselineNoise; // Giá trị nhiễu nền (từ thanh trượt)
  final String? errorMessage;

  // Đây là giá trị đã lọc để hiển thị
  double get displayedValue {
    final val = rawValue - baselineNoise;
    return val < 0 ? 0.0 : val; // sẽ không hiển thị giá trị âm
  }

  const MagneticScannerState({
    required this.status,
    required this.rawValue,
    required this.baselineNoise,
    this.errorMessage,
  });

  factory MagneticScannerState.initial() {
    return const MagneticScannerState(
      status: MagneticScannerStatus.initial,
      rawValue: 0.0,
      baselineNoise: 0.0,
    );
  }

  MagneticScannerState copyWith({
    MagneticScannerStatus? status,
    double? rawValue,
    double? baselineNoise,
    String? errorMessage,
  }) {
    return MagneticScannerState(
      status: status ?? this.status,
      rawValue: rawValue ?? this.rawValue,
      baselineNoise: baselineNoise ?? this.baselineNoise,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rawValue, baselineNoise, errorMessage];
}
