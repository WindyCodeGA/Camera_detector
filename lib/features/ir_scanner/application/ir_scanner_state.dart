part of 'ir_scanner_bloc.dart';

// Enum cho trạng thái chung
enum IrScannerStatus { initial, loading, ready, recording, error }

// Enum cho các bộ lọc
enum IRFilter { red, green, blue, normal, greyscale }

class IrScannerState extends Equatable {
  final IrScannerStatus status;
  final CameraController? cameraController;
  final IRFilter currentFilter;
  final bool isFlashlightOn;
  final bool isRecording;

  // Biến chứa file video vừa quay xong (để UI hiện thông báo)
  final XFile? lastRecordedVideo;

  final String? errorMessage;

  const IrScannerState({
    required this.status,
    this.cameraController,
    required this.currentFilter,
    required this.isFlashlightOn,
    required this.isRecording,
    this.lastRecordedVideo,
    this.errorMessage,
  });

  // Trạng thái khởi tạo
  factory IrScannerState.initial() {
    return const IrScannerState(
      status: IrScannerStatus.initial,
      cameraController: null,
      currentFilter: IRFilter.red, // Mặc định là bộ lọc đỏ
      isFlashlightOn: false,
      isRecording: false,
      lastRecordedVideo: null,
    );
  }

  // Hàm copyWith
  IrScannerState copyWith({
    IrScannerStatus? status,
    CameraController? cameraController,
    IRFilter? currentFilter,
    bool? isFlashlightOn,
    bool? isRecording,
    XFile? lastRecordedVideo,
    String? errorMessage,
  }) {
    return IrScannerState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      currentFilter: currentFilter ?? this.currentFilter,
      isFlashlightOn: isFlashlightOn ?? this.isFlashlightOn,
      isRecording: isRecording ?? this.isRecording,
      lastRecordedVideo: lastRecordedVideo ?? this.lastRecordedVideo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    cameraController,
    currentFilter,
    isFlashlightOn,
    isRecording,
    lastRecordedVideo,
    errorMessage,
  ];
}
