import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

part 'ir_scanner_event.dart';
part 'ir_scanner_state.dart';

class IrScannerBloc extends Bloc<IrScannerEvent, IrScannerState>
    with WidgetsBindingObserver {
  List<CameraDescription>? _cameras;

  IrScannerBloc() : super(IrScannerState.initial()) {
    // Đây là các đăng ký các trình xử lý sự kiện
    on<IrCameraInitialize>(_onCameraInitialize);
    on<IrFilterChanged>(_onFilterChanged);
    on<IrFlashlightToggled>(_onFlashlightToggled);
    on<IrVideoRecordingStarted>(_onVideoRecordingStarted);
    on<IrVideoRecordingStopped>(_onVideoRecordingStopped);
    on<_IrAppLifecycleChanged>(_onAppLifecycleChanged);

    // ở đây tôi dùng bắt đầu vòng đời
    WidgetsBinding.instance.addObserver(this);
  }

  // --- Lắng nghe App Lifecycle ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    add(_IrAppLifecycleChanged(state));
  }

  // --- Trình xử lý sự kiện ---

  Future<void> _onCameraInitialize(
    IrCameraInitialize event,
    Emitter<IrScannerState> emit,
  ) async {
    // Nếu camera đang chạy rồi thì không khởi tạo lại
    if (state.cameraController != null) return;

    emit(state.copyWith(status: IrScannerStatus.loading));

    try {
      // 1. KIỂM TRA QUYỀN
      //(Không request, chỉ check status để tránh crash UI)
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        emit(
          state.copyWith(
            status: IrScannerStatus.error,
            errorMessage: "PERMISSION_DENIED",
          ),
        );
        return;
      }

      // 2. Lấy danh sách Camera
      _cameras ??= await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception("No available cameras found.");
      }

      // 3. Chọn camera sau
      CameraDescription? rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // 4. Tạo Controller
      final controller = CameraController(
        rearCamera,

        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      emit(
        state.copyWith(
          status: IrScannerStatus.ready,
          cameraController: controller,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Thay đổi bộ lọc màu
  void _onFilterChanged(IrFilterChanged event, Emitter<IrScannerState> emit) {
    emit(state.copyWith(currentFilter: event.filter));
  }

  // Bật/tắt đèn flash
  Future<void> _onFlashlightToggled(
    IrFlashlightToggled event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (state.isFlashlightOn) {
        await controller.setFlashMode(FlashMode.off);
      } else {
        await controller.setFlashMode(FlashMode.torch);
      }
      emit(state.copyWith(isFlashlightOn: !state.isFlashlightOn));
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: "On/off error Flash: $e",
        ),
      );
    }
  }

  Future<void> _onAppLifecycleChanged(
    _IrAppLifecycleChanged event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;

    if (event.state == AppLifecycleState.inactive) {
      // Khi app ẩn xuống, giải phóng camera ngay để tránh lỗi không sử dụng dẫn đến crash
      if (controller != null) {
        await controller.dispose();
        emit(IrScannerState.initial());
      }
    } else if (event.state == AppLifecycleState.resumed) {
      // Khi app hiện lên, khởi tạo lại
      if (controller == null) {
        add(IrCameraInitialize());
      }
    }
  }

  // --- Logic Quay Video ---

  Future<void> _onVideoRecordingStarted(
    IrVideoRecordingStarted event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.startVideoRecording();
      emit(
        state.copyWith(status: IrScannerStatus.recording, isRecording: true),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: "Error starting to spin: $e",
        ),
      );
    }
  }

  Future<void> _onVideoRecordingStopped(
    IrVideoRecordingStopped event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !state.isRecording) {
      return;
    }

    try {
      //  Dừng quay và lấy file
      final XFile videoFile = await controller.stopVideoRecording();

      //  Lưu vào Gallery (Thư viện ảnh)
      // Hàm này sẽ tự động xin quyền truy cập thư viện nếu chưa có
      await Gal.putVideo(videoFile.path);

      //  Cập nhật State
      emit(
        state.copyWith(
          status: IrScannerStatus.ready,
          isRecording: false,
          lastRecordedVideo:
              videoFile, // Lưu file vào state để UI hiện thông báo
        ),
      );

      log("The video has been saved to Gallery: ${videoFile.path}");
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: "Error stopping/saving video: $e",
        ),
      );
    }
  }

  // --- Dọn dẹp ---
  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    state.cameraController?.dispose();
    return super.close();
  }
}
