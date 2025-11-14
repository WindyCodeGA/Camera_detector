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
    on<PermissionRequested>(_onPermissionRequested);
    on<_ScanResultsUpdated>(_onResultsUpdated);
    on<_PermissionStatusChanged>(_onPermissionStatusChanged);
    on<_ScanFailed>(_onScanFailed);

    // Bắt đầu bằng việc kiểm tra quyền ngay lập tức
    add(PermissionRequested());
  }

  // --- Trình xử lý sự kiện ---

  // Xử lý khi người dùng nhấn "Start Scan"
  Future<void> _onScanStarted(
    ScanStarted event,
    Emitter<WifiScannerState> emit,
  ) async {
    // 1. Kiểm tra quyền một lần nữa
    final status = await Permission.location.status;
    if (!status.isGranted) {
      emit(state.copyWith(status: WifiScannerStatus.permissionDenied));
      return;
    }

    // 2. Chuyển sang trạng thái "loading" (giống code cũ)
    emit(state.copyWith(status: WifiScannerStatus.loading));

    // 3. Đợi 3 giây (giống code cũ)
    await Future.delayed(const Duration(seconds: 3));

    // 4. Bắt đầu quét
    _startPeriodicScan();
    emit(state.copyWith(status: WifiScannerStatus.scanning));
  }

  // Xử lý khi yêu cầu quyền
  Future<void> _onPermissionRequested(
    PermissionRequested event,
    Emitter<WifiScannerState> emit,
  ) async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Nếu được cấp quyền, quay về màn hình 'initial' (sẵn sàng)
      emit(state.copyWith(status: WifiScannerStatus.initial));
    } else {
      // Nếu từ chối, hiển thị lỗi
      emit(state.copyWith(status: WifiScannerStatus.permissionDenied));
    }
  }

  // Xử lý khi có kết quả Wi-Fi mới
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

  // --- Logic phụ trợ ---

  // Bắt đầu timer quét
  void _startPeriodicScan() {
    _scanTimer?.cancel(); // Hủy timer cũ nếu có

    // Quét ngay lập tức 1 lần
    _scanWifi();

    // Sau đó quét định kỳ mỗi 2 giây
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) => _scanWifi());
  }

  void _onPermissionStatusChanged(
    _PermissionStatusChanged event,
    Emitter<WifiScannerState> emit,
  ) {}

  void _onScanFailed(_ScanFailed event, Emitter<WifiScannerState> emit) {
    emit(
      state.copyWith(
        status: WifiScannerStatus.error,
        errorMessage: event.errorMessage,
      ),
    );
  }

  // Hàm quét Wi-Fi
  Future<void> _scanWifi() async {
    try {
      final canStartScan = await WiFiScan.instance.startScan();
      if (canStartScan != true) {
        // Xử lý lỗi nếu không thể bắt đầu quét
        addError(Exception("Không thể bắt đầu quét Wi-Fi"));
        return;
      }

      final results = await WiFiScan.instance.getScannedResults();

      add(_ScanResultsUpdated(results));
    } catch (e) {
      addError(e);
      add(_ScanFailed(e.toString()));
    }
  }

  // --- Dọn dẹp ---
  @override
  Future<void> close() {
    _scanTimer?.cancel();
    return super.close();
  }
}
