part of 'ir_scanner_bloc.dart';

abstract class IrScannerEvent extends Equatable {
  const IrScannerEvent();

  @override
  List<Object?> get props => [];
}

// Yêu cầu BLoC khởi tạo camera
class IrCameraInitialize extends IrScannerEvent {}

// Thay đổi bộ lọc màu
class IrFilterChanged extends IrScannerEvent {
  final IRFilter filter;
  const IrFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

// Bật/tắt đèn flash
class IrFlashlightToggled extends IrScannerEvent {}

// Bắt đầu quay video
class IrVideoRecordingStarted extends IrScannerEvent {}

// Dừng quay video
class IrVideoRecordingStopped extends IrScannerEvent {}

// --- Sự kiện nội bộ BLoC ---

class _IrAppLifecycleChanged extends IrScannerEvent {
  final AppLifecycleState state;
  const _IrAppLifecycleChanged(this.state);

  @override
  List<Object?> get props => [state];
}
