part of 'magnetic_scanner_bloc.dart';

abstract class MagneticScannerEvent extends Equatable {
  const MagneticScannerEvent();
  @override
  List<Object> get props => [];
}

// Bắt đầu lắng nghe cảm biến
class MagneticScanStarted extends MagneticScannerEvent {}

// Dừng lắng nghe cảm biến (khi ta  rời màn hình)
class MagneticScanStopped extends MagneticScannerEvent {}

//  Cập nhật giá trị từ cảm biến
class _MagneticSensorUpdated extends MagneticScannerEvent {
  final MagnetometerEvent sensorEvent;
  const _MagneticSensorUpdated(this.sensorEvent);

  @override
  List<Object> get props => [sensorEvent];
}

//  Khi ta  dùng kéo thanh trượt
class BaselineNoiseChanged extends MagneticScannerEvent {
  final double newBaseline;
  const BaselineNoiseChanged(this.newBaseline);

  @override
  List<Object> get props => [newBaseline];
}
