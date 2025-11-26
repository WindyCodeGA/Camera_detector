import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'magnetic_scanner_event.dart';
part 'magnetic_scanner_state.dart';

class MagneticScannerBloc
    extends Bloc<MagneticScannerEvent, MagneticScannerState> {
  StreamSubscription? _sensorSubscription;

  MagneticScannerBloc() : super(MagneticScannerState.initial()) {
    on<MagneticScanStarted>(_onScanStarted);
    on<MagneticScanStopped>(_onScanStopped);
    on<_MagneticSensorUpdated>(_onSensorUpdated);
    on<BaselineNoiseChanged>(_onBaselineNoiseChanged);
  }

  // Bắt đầu lắng nghe
  void _onScanStarted(
    MagneticScanStarted event,
    Emitter<MagneticScannerState> emit,
  ) {
    _sensorSubscription?.cancel();
    _sensorSubscription = magnetometerEvents.listen(
      (sensorEvent) {
        add(_MagneticSensorUpdated(sensorEvent));
      },
      onError: (e) {
        emit(
          state.copyWith(
            status: MagneticScannerStatus.error,
            errorMessage: e.toString(),
          ),
        );
      },
      cancelOnError: true,
    );
    emit(state.copyWith(status: MagneticScannerStatus.scanning));
  }

  // Dừng lắng nghe
  void _onScanStopped(
    MagneticScanStopped event,
    Emitter<MagneticScannerState> emit,
  ) {
    _sensorSubscription?.cancel();
    // Giữ nguyên giá trị baseline, chỉ dừng quét
    emit(state.copyWith(status: MagneticScannerStatus.initial));
  }

  // Cập nhật giá trị từ cảm biến
  void _onSensorUpdated(
    _MagneticSensorUpdated event,
    Emitter<MagneticScannerState> emit,
  ) {
    double x = event.sensorEvent.x;
    double y = event.sensorEvent.y;
    double z = event.sensorEvent.z;

    // Tính toán độ lớn tổng của từ trường
    double totalStrength = sqrt(x * x + y * y + z * z);

    emit(
      state.copyWith(
        status: MagneticScannerStatus.scanning,
        rawValue: totalStrength, // Lưu vào giá trị thô
      ),
    );
  }

  // HANDLER MỚI: Xử lý sự kiện kéo thanh trượt
  void _onBaselineNoiseChanged(
    BaselineNoiseChanged event,
    Emitter<MagneticScannerState> emit,
  ) {
    emit(state.copyWith(baselineNoise: event.newBaseline));
  }

  @override
  Future<void> close() {
    _sensorSubscription?.cancel();
    return super.close();
  }
}
