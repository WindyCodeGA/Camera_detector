import 'dart:async';
import 'dart:developer'; // Dùng thư viện này để log
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Cần cho AppLifecycleState
import 'package:permission_handler/permission_handler.dart';

part 'ir_scanner_event.dart';
part 'ir_scanner_state.dart';

class IrScannerBloc extends Bloc<IrScannerEvent, IrScannerState>
    with WidgetsBindingObserver {
  // Mixin để lắng nghe app lifecycle

  List<CameraDescription>? _cameras;

  IrScannerBloc() : super(IrScannerState.initial()) {
    // Đăng ký các trình xử lý sự kiện
    on<IrCameraInitialize>(_onCameraInitialize);
    on<IrFilterChanged>(_onFilterChanged);
    on<IrFlashlightToggled>(_onFlashlightToggled);
    on<IrVideoRecordingStarted>(_onVideoRecordingStarted);
    on<IrVideoRecordingStopped>(_onVideoRecordingStopped);
    on<_IrAppLifecycleChanged>(_onAppLifecycleChanged);

    // Bắt đầu lắng nghe app lifecycle
    WidgetsBinding.instance.addObserver(this);
  }

  // --- Lắng nghe App Lifecycle ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Thêm sự kiện nội bộ vào BLoC
    add(_IrAppLifecycleChanged(state));
  }

  // --- Trình xử lý sự kiện ---

  Future<void> _onCameraInitialize(
    IrCameraInitialize event,
    Emitter<IrScannerState> emit,
  ) async {
    // Nếu camera đang chạy rồi thì không khởi tạo lại
    if (state.cameraController != null) {
      return;
    }

    emit(state.copyWith(status: IrScannerStatus.loading));

    try {
      // 1. KIỂM TRA QUYỀN (QUAN TRỌNG)
      // Chúng ta chỉ kiểm tra 'status', KHÔNG gọi 'request()'
      // Để tránh xung đột UI (Race Condition)
      final status = await Permission.camera.status;

      // Nếu chưa được cấp quyền (Denied, PermanentlyDenied, Restricted...)
      if (!status.isGranted) {
        // Emit mã lỗi đặc biệt để UI hiển thị nút "Cho phép"
        emit(
          state.copyWith(
            status: IrScannerStatus.error,
            errorMessage: "PERMISSION_DENIED",
          ),
        );
        return; // Dừng lại ngay, không cố mở camera
      }

      // 2. Lấy danh sách Camera (chỉ một lần)
      _cameras ??= await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception("Không tìm thấy camera khả dụng.");
      }

      // 3. Chọn camera sau (Back Camera)
      CameraDescription? rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // 4. Tạo và khởi tạo Controller
      final controller = CameraController(
        rearCamera,
        ResolutionPreset
            .low, // Low để tối ưu hiệu năng cho Image Processing sau này
        enableAudio: false, // Tắt audio (tránh lỗi quyền Micro khi chưa xin)
      );

      await controller.initialize();

      // 5. Emit trạng thái "Ready"
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
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

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
          errorMessage: "Lỗi bật/tắt Flash: $e",
        ),
      );
    }
  }

  // Xử lý khi app lifecycle thay đổi (Vào nền/Quay lại)
  Future<void> _onAppLifecycleChanged(
    _IrAppLifecycleChanged event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;

    if (event.state == AppLifecycleState.inactive) {
      // Khi app bị tạm dừng (ví dụ: kéo notification, nhấn Home), tắt controller
      if (controller != null) {
        await controller.dispose();
        // Reset về trạng thái ban đầu để giải phóng RAM
        emit(IrScannerState.initial());
      }
    } else if (event.state == AppLifecycleState.resumed) {
      // Khi app quay lại, thử khởi tạo lại camera
      if (controller == null) {
        add(IrCameraInitialize());
      }
    }
  }

  // --- Logic Quay video (Chuẩn bị cho tương lai) ---

  Future<void> _onVideoRecordingStarted(
    IrVideoRecordingStarted event,
    Emitter<IrScannerState> emit,
  ) async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    // Lưu ý: Để quay video có tiếng, bạn cần xin thêm quyền Microphone
    // và set enableAudio: true ở phần khởi tạo controller.

    try {
      await controller.startVideoRecording();
      emit(
        state.copyWith(status: IrScannerStatus.recording, isRecording: true),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: "Lỗi bắt đầu quay: $e",
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
      final XFile videoFile = await controller.stopVideoRecording();

      emit(
        state.copyWith(
          status:
              IrScannerStatus.ready, // Quay về trạng thái sẵn sàng (Preview)
          isRecording: false,
        ),
      );

      // Log đường dẫn file
      log("Video đã được lưu tại: ${videoFile.path}");

      // TODO: Ở đây bạn có thể thêm logic lưu vào Gallery (dùng gal hoặc gallery_saver)
    } catch (e) {
      emit(
        state.copyWith(
          status: IrScannerStatus.error,
          errorMessage: "Lỗi dừng quay: $e",
        ),
      );
    }
  }

  // --- Dọn dẹp ---
  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this); // Ngừng lắng nghe lifecycle
    state.cameraController?.dispose(); // Hủy controller khi BLoC bị đóng
    return super.close();
  }
}
