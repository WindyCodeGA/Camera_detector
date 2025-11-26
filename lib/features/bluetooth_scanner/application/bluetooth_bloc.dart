import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothScannerBloc
    extends Bloc<BluetoothScannerEvent, BluetoothScannerState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _chartUpdateTimer;

  BluetoothScannerBloc() : super(BluetoothScannerState.initial()) {
    // Đăng ký các trình xử lý sự kiện
    on<ToggleScanEvent>(_onToggleScan);

    // --- THÊM SỰ KIỆN DỪNG MỚI ---
    on<StopScanEvent>(_onStopScan);
    // -----------------------------

    on<ApplyFiltersEvent>(_onApplyFilters);
    on<_IsScanningUpdatedEvent>(_onIsScanningUpdated);
    on<_ScanResultsUpdatedEvent>(_onScanResultsUpdated);
    on<_AdapterStateUpdatedEvent>(_onAdapterStateUpdated);
    on<_UpdateChartEvent>(_onUpdateChart);

    // --- QUAN TRỌNG: ĐÃ XÓA CÁC DÒNG KHỞI TẠO TỰ ĐỘNG ---
    // _setupBluetoothSubscriptions();  <-- XÓA
    // _startChartUpdateTimer();        <-- XÓA

    // Chỉ lắng nghe adapter state (để biết bluetooth bật/tắt) là an toàn
    _listenToAdapterState();
  }

  // Chỉ lắng nghe trạng thái Adapter (nhẹ nhàng)
  void _listenToAdapterState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
      (adapterState) => add(_AdapterStateUpdatedEvent(adapterState)),
      onError: (e) => debugPrint("Lỗi adapterState stream: $e"),
    );
  }

  // Hàm này sẽ được gọi khi BẮT ĐẦU QUÉT
  void _startListeningToScanResults() {
    // Hủy cái cũ nếu có để tránh duplicate
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _chartUpdateTimer?.cancel();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) => add(_ScanResultsUpdatedEvent(results)),
      onError: (e) => debugPrint("Lỗi scanResults stream: $e"),
    );

    _isScanningSubscription = FlutterBluePlus.isScanning.listen(
      (isScanning) => add(_IsScanningUpdatedEvent(isScanning)),
      onError: (e) => debugPrint("Lỗi isScanning stream: $e"),
    );

    _chartUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      add(_UpdateChartEvent());
    });
  }

  // --- Trình xử lý sự kiện (Event Handlers) ---

  Future<void> _onToggleScan(
    ToggleScanEvent event,
    Emitter<BluetoothScannerState> emit,
  ) async {
    if (state.isScanning) {
      await FlutterBluePlus.stopScan();
    } else {
      // BẮT ĐẦU QUÉT
      if (state.status == ScannerStatus.adapterOff) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          debugPrint("Không thể bật Bluetooth: $e");
          return;
        }
      }

      // Kích hoạt lắng nghe stream KHI CẦN
      _startListeningToScanResults();

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
  }

  // --- SỰ KIỆN DỪNG MỚI (Dùng khi rời màn hình) ---
  Future<void> _onStopScan(
    StopScanEvent event,
    Emitter<BluetoothScannerState> emit,
  ) async {
    // Dừng quét
    await FlutterBluePlus.stopScan();

    // Hủy lắng nghe để tiết kiệm tài nguyên
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _chartUpdateTimer?.cancel();

    // Reset một phần trạng thái nếu muốn
    emit(state.copyWith(isScanning: false, status: ScannerStatus.stopped));
  }
  // ----------------------------------------------

  // ... (Các hàm _onIsScanningUpdated, _onAdapterStateUpdated... GIỮ NGUYÊN) ...
  void _onIsScanningUpdated(
    _IsScanningUpdatedEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    if (event.isScanning) {
      emit(
        state.copyWith(
          isScanning: true,
          status: ScannerStatus.scanning,
          allScanResults: [],
          filteredScanResults: [],
          avgRssi: 0.0,
        ),
      );
    } else {
      emit(state.copyWith(isScanning: false, status: ScannerStatus.stopped));
    }
  }

  void _onAdapterStateUpdated(
    _AdapterStateUpdatedEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    if (event.adapterState == BluetoothAdapterState.off) {
      emit(
        BluetoothScannerState.initial().copyWith(
          status: ScannerStatus.adapterOff,
        ),
      );
    } else if (event.adapterState == BluetoothAdapterState.on &&
        state.status == ScannerStatus.adapterOff) {
      emit(state.copyWith(status: ScannerStatus.initial));
    }
  }

  void _onScanResultsUpdated(
    _ScanResultsUpdatedEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    final allResults = event.results;
    final filteredResults = _applyFilterLogic(
      allResults,
      state.minRssiFilter,
      state.onlyNamedDevices,
      state.onlyConnectableDevices,
    );
    final avgRssi = _calculateAvgRssi(filteredResults);

    emit(
      state.copyWith(
        allScanResults: allResults,
        filteredScanResults: filteredResults,
        avgRssi: avgRssi,
      ),
    );
  }

  void _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    emit(
      state.copyWith(
        minRssiFilter: event.minRssi,
        onlyNamedDevices: event.onlyNamedDevices,
        onlyConnectableDevices: event.onlyConnectableDevices,
      ),
    );
    final filteredResults = _applyFilterLogic(
      state.allScanResults,
      event.minRssi,
      event.onlyNamedDevices,
      event.onlyConnectableDevices,
    );
    final avgRssi = _calculateAvgRssi(filteredResults);
    emit(
      state.copyWith(filteredScanResults: filteredResults, avgRssi: avgRssi),
    );
  }

  void _onUpdateChart(
    _UpdateChartEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    final newX = state.chartXValue + 1;
    final newChartData = List<FlSpot>.from(state.chartData);
    if (newChartData.length >= 10) {
      newChartData.removeAt(0);
    }
    newChartData.add(
      FlSpot(newX.toDouble(), state.filteredScanResults.length.toDouble()),
    );
    emit(state.copyWith(chartData: newChartData, chartXValue: newX));
  }

  // ... (Các hàm logic phụ trợ giữ nguyên) ...
  List<ScanResult> _applyFilterLogic(
    List<ScanResult> allResults,
    double minRssi,
    bool onlyNamed,
    bool onlyConnectable,
  ) {
    List<ScanResult> tempResults = List.from(allResults);
    tempResults = tempResults.where((r) => r.rssi >= minRssi).toList();
    if (onlyNamed) {
      tempResults = tempResults
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
    }
    if (onlyConnectable) {
      tempResults = tempResults
          .where((r) => r.advertisementData.connectable)
          .toList();
    }
    tempResults.sort((a, b) => b.rssi.compareTo(a.rssi));
    return tempResults;
  }

  double _calculateAvgRssi(List<ScanResult> results) {
    if (results.isEmpty) return 0.0;
    double sumRssi = results.map((r) => r.rssi).sum.toDouble();
    return sumRssi / results.length;
  }

  @override
  Future<void> close() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _chartUpdateTimer?.cancel();
    FlutterBluePlus.stopScan();
    return super.close();
  }
}
