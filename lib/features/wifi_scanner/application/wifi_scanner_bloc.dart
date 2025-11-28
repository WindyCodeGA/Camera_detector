import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

part 'wifi_scanner_event.dart';
part 'wifi_scanner_state.dart';

class WifiScannerBloc extends Bloc<WifiScannerEvent, WifiScannerState> {
  Timer? _scanTimer;

  WifiScannerBloc() : super(WifiScannerState.initial()) {
    // Đăng ký các trình xử lý sự kiện
    on<ScanStarted>(_onScanStarted);
    on<ScanStopped>(_onScanStopped); // <--- ĐĂNG KÝ SỰ KIỆN MỚI
    on<PermissionRequested>(_onPermissionRequested);
    on<_ScanResultsUpdated>(_onResultsUpdated);
    on<_ScanFailed>(_onScanFailed);

    // --- QUAN TRỌNG: ĐÃ XÓA DÒNG NÀY ---
    // add(PermissionRequested());
    // (Để UI tự gọi khi cần, không gọi tự động gây lag)
  }

  // --- Trình xử lý sự kiện ---

  // 1. BẮT ĐẦU QUÉT
  Future<void> _onScanStarted(
    ScanStarted event,
    Emitter<WifiScannerState> emit,
  ) async {
    // 1. Kiểm tra QUYỀN (Permission) - Code cũ
    final status = await Permission.location.status;
    if (!status.isGranted) {
      // Nếu chưa có quyền -> Thử xin quyền
      add(PermissionRequested());
      return;
    }

    // --- THÊM ĐOẠN NÀY: Kiểm tra GPS (Service) ---
    // Kiểm tra xem người dùng có bật công tắc Vị trí/GPS không
    if (await Permission.location.serviceStatus.isDisabled) {
      emit(
        state.copyWith(
          status: WifiScannerStatus.error,
          errorMessage: "Vui lòng bật GPS (Vị trí) để quét Wi-Fi",
        ),
      );
      return; // Dừng lại, không quét nữa
    }

    // Chuyển sang loading
    emit(state.copyWith(status: WifiScannerStatus.loading));

    // Giả lập delay 3 giây (animation)
    await Future.delayed(const Duration(seconds: 3));

    // Bắt đầu quét định kỳ
    _startPeriodicScan();
    emit(state.copyWith(status: WifiScannerStatus.scanning));
  }

  // 2. DỪNG QUÉT (MỚI) - Dùng khi chuyển tab
  Future<void> _onScanStopped(
    ScanStopped event,
    Emitter<WifiScannerState> emit,
  ) async {
    _scanTimer?.cancel(); // Hủy timer
    // Reset về trạng thái ban đầu (hoặc giữ nguyên list nếu muốn)
    emit(state.copyWith(status: WifiScannerStatus.initial));
  }

  // 3. XIN QUYỀN
  Future<void> _onPermissionRequested(
    PermissionRequested event,
    Emitter<WifiScannerState> emit,
  ) async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Nếu được cấp quyền, tự động bắt đầu quy trình quét
      add(ScanStarted());
    } else {
      emit(state.copyWith(status: WifiScannerStatus.permissionDenied));
    }
  }

  // 4. CẬP NHẬT KẾT QUẢ
  void _onResultsUpdated(
    _ScanResultsUpdated event,
    Emitter<WifiScannerState> emit,
  ) {
    emit(
      state.copyWith(
        status: WifiScannerStatus.scanning,
        networks: event.networks,
      ),
    );
  }

  // 5. XỬ LÝ LỖI
  void _onScanFailed(_ScanFailed event, Emitter<WifiScannerState> emit) {
    emit(
      state.copyWith(
        status: WifiScannerStatus.error,
        errorMessage: event.errorMessage,
      ),
    );
  }

  // --- Logic phụ trợ ---

  void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanWifi(); // Quét ngay phát đầu tiên
    // Quét lại mỗi 5 giây (2 giây là hơi nhanh, dễ gây lag máy)
    _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) => _scanWifi());
  }

  Future<void> _scanWifi() async {
    try {
      // Kiểm tra xem có thể quét không
      final canScan = await WiFiScan.instance.canStartScan(
        askPermissions: false,
      );
      if (canScan != CanStartScan.yes) {
        // Nếu không quét được (do phần cứng hoặc throttle), bỏ qua lượt này
        return;
      }

      final started = await WiFiScan.instance.startScan();
      if (started) {
        final results = await WiFiScan.instance.getScannedResults();
        add(_ScanResultsUpdated(results));
      }
    } catch (e) {
      add(_ScanFailed(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    return super.close();
  }
}
