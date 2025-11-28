import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';

// Import Model
import '../models/bluetooth_device_model.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothScannerBloc
    extends Bloc<BluetoothScannerEvent, BluetoothScannerState> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _chartUpdateTimer;

  BluetoothScannerBloc() : super(BluetoothScannerState.initial()) {
    on<ToggleScanEvent>(_onToggleScan);
    on<StopScanEvent>(_onStopScan); // <--- Sự kiện Dừng
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<_IsScanningUpdatedEvent>(_onIsScanningUpdated);
    on<_ScanResultsUpdatedEvent>(_onScanResultsUpdated);
    on<_AdapterStateUpdatedEvent>(_onAdapterStateUpdated);
    on<_UpdateChartEvent>(_onUpdateChart);

    // Constructor SẠCH: Chỉ lắng nghe trạng thái adapter
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
      (adapterState) => add(_AdapterStateUpdatedEvent(adapterState)),
      onError: (e) => debugPrint("Lỗi adapterState stream: $e"),
    );
  }

  void _startListening() {
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

  Future<void> _onToggleScan(
    ToggleScanEvent event,
    Emitter<BluetoothScannerState> emit,
  ) async {
    if (state.isScanning) {
      add(StopScanEvent());
    } else {
      // 1. Kiểm tra quyền
      if (defaultTargetPlatform == TargetPlatform.android) {
        var statusScan = await Permission.bluetoothScan.request();
        var statusConnect = await Permission.bluetoothConnect.request();
        var statusLoc = await Permission.location.request();
        if (statusScan.isDenied ||
            statusConnect.isDenied ||
            statusLoc.isDenied) {
          return;
        }
      }

      // 2. Bật Bluetooth
      if (state.status == ScannerStatus.adapterOff &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 3. Quét
      _startListening();
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      } catch (e) {
        debugPrint("Lỗi quét: $e");
      }
    }
  }

  Future<void> _onStopScan(
    StopScanEvent event,
    Emitter<BluetoothScannerState> emit,
  ) async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _chartUpdateTimer?.cancel();
    emit(state.copyWith(isScanning: false, status: ScannerStatus.stopped));
  }

  // --- LOGIC TÍNH ĐIỂM RỦI RO ---
  BluetoothDeviceModel _calculateRisk(ScanResult r) {
    double risk = 0.0;
    final rssi = r.rssi;
    final name = r.device.platformName.toLowerCase();

    // 1. Tín hiệu mạnh
    if (rssi > -50) {
      risk += 45;
    } else if (rssi > -70) {
      risk += 20;
    }

    // 2. Tên thiết bị
    if (name.isEmpty) {
      risk += 25;
    } else {
      final suspicious = ['cam', 'hidden', 'esp', 'hc-', 'sh-', 'bt-'];
      if (suspicious.any((s) => name.contains(s))) risk += 15;
    }

    // 3. Service UUIDs
    final suspiciousUUIDs = ['180d', 'ffe0', 'dfb0', 'fe00'];
    for (var uuid in r.advertisementData.serviceUuids) {
      if (suspiciousUUIDs.any((s) => uuid.toString().contains(s))) {
        risk += 20;
        break;
      }
    }

    // 4. Connectable
    if (r.advertisementData.connectable) risk += 10;

    return BluetoothDeviceModel(
      scanResult: r,
      riskScore: risk.clamp(0.0, 100.0),
    );
  }

  void _onScanResultsUpdated(
    _ScanResultsUpdatedEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    // Chuyển đổi sang Model và tính điểm
    final allModels = event.results.map(_calculateRisk).toList();

    final filteredModels = _applyFilterLogic(
      allModels,
      state.minRssiFilter,
      state.onlyNamedDevices,
      state.onlyConnectableDevices,
    );

    emit(
      state.copyWith(
        allScanResults: allModels,
        filteredScanResults: filteredModels,
        avgRssi: _calculateAvgRssi(filteredModels),
      ),
    );
  }

  // ... (Các phần Filter, Chart, AdapterUpdate giữ nguyên như cũ) ...

  void _onIsScanningUpdated(
    _IsScanningUpdatedEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    if (event.isScanning) {
      emit(state.copyWith(isScanning: true, status: ScannerStatus.scanning));
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
    } else if (event.adapterState == BluetoothAdapterState.on) {
      emit(state.copyWith(status: ScannerStatus.initial));
    }
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
    final filtered = _applyFilterLogic(
      state.allScanResults,
      event.minRssi,
      event.onlyNamedDevices,
      event.onlyConnectableDevices,
    );
    emit(
      state.copyWith(
        filteredScanResults: filtered,
        avgRssi: _calculateAvgRssi(filtered),
      ),
    );
  }

  void _onUpdateChart(
    _UpdateChartEvent event,
    Emitter<BluetoothScannerState> emit,
  ) {
    final newX = state.chartXValue + 1;
    final newChartData = List<FlSpot>.from(state.chartData);
    if (newChartData.length >= 10) newChartData.removeAt(0);
    newChartData.add(
      FlSpot(newX.toDouble(), state.filteredScanResults.length.toDouble()),
    );
    emit(state.copyWith(chartData: newChartData, chartXValue: newX));
  }

  List<BluetoothDeviceModel> _applyFilterLogic(
    List<BluetoothDeviceModel> list,
    double minRssi,
    bool named,
    bool connectable,
  ) {
    var temp = list.where((m) => m.scanResult.rssi >= minRssi).toList();
    if (named) temp = temp.where((m) => m.name != 'Unknown Device').toList();
    if (connectable) {
      temp = temp
          .where((m) => m.scanResult.advertisementData.connectable)
          .toList();
    }

    temp.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return temp;
  }

  double _calculateAvgRssi(List<BluetoothDeviceModel> list) {
    if (list.isEmpty) return 0.0;
    return list.fold(0.0, (sum, m) => sum + m.scanResult.rssi) / list.length;
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
