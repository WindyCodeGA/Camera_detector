import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Không cần thư viện này nữa
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:soundpool/soundpool.dart'; // ĐÃ XÓA
import 'package:audioplayers/audioplayers.dart'; // ĐÃ THÊM
import 'package:vibration/vibration.dart';

// Import BLoC
import '../../application/magnetic_scanner_bloc.dart';
// Import Widget đồng hồ
import 'package:camera_detector/features/magnetic_field/presentation/widgets/magnetic_gauge.dart';

class MagneticFieldScannerScreen extends StatefulWidget {
  const MagneticFieldScannerScreen({super.key});

  @override
  State<MagneticFieldScannerScreen> createState() =>
      _MagneticFieldScannerScreenState();
}

class _MagneticFieldScannerScreenState
    extends State<MagneticFieldScannerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isBeepLoaded = false;

  Timer? _feedbackTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    context.read<MagneticScannerBloc>().add(MagneticScanStarted());
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    context.read<MagneticScannerBloc>().add(MagneticScanStopped());
    _feedbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      if (!_isDisposed) {
        setState(() {
          _isBeepLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải file âm thanh 'beep.mp3': $e");
    }
  }

  void _triggerFeedback(double displayedValue) {
    if (_isDisposed) return;

    _feedbackTimer?.cancel();
    Duration? newInterval;

    if (displayedValue > 30) {
      newInterval = const Duration(milliseconds: 200);
    } else if (displayedValue > 10) {
      newInterval = const Duration(milliseconds: 700);
    }

    if (newInterval != null && _isBeepLoaded) {
      _feedbackTimer = Timer.periodic(newInterval, (_) async {
        if (_isDisposed) {
          _feedbackTimer?.cancel();
          return;
        }

        try {
          await _audioPlayer.stop();

          await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        } catch (e) {
          debugPrint("Lỗi phát âm thanh: $e");
        }

        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 50);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MagneticScannerBloc, MagneticScannerState>(
      listenWhen: (prev, curr) =>
          prev.displayedValue != curr.displayedValue ||
          prev.status != curr.status,
      listener: (context, state) {
        if (state.status == MagneticScannerStatus.scanning) {
          _triggerFeedback(state.displayedValue);
        } else {
          _feedbackTimer?.cancel();
        }
      },
      child: BlocBuilder<MagneticScannerBloc, MagneticScannerState>(
        builder: (context, state) {
          if (state.status == MagneticScannerStatus.error) {
            return Center(child: Text("Lỗi cảm biến: ${state.errorMessage}"));
          }

          // Giao diện chính
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- 1. Tiêu đề ---
                const Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Magnetometer",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Detect strong magnetic fields"),
                  ],
                ),

                MagneticGauge(value: state.displayedValue, maximum: 200.0),

                _buildSensitivitySlider(context, state.baselineNoise),

                // --- 4. Nút Stop/Start ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (state.status == MagneticScannerStatus.scanning) {
                      context.read<MagneticScannerBloc>().add(
                        MagneticScanStopped(),
                      );
                    } else {
                      context.read<MagneticScannerBloc>().add(
                        MagneticScanStarted(),
                      );
                    }
                  },
                  child: Text(
                    state.status == MagneticScannerStatus.scanning
                        ? "Stop"
                        : "Start",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET THANH TRƯỢT (GIỮ NGUYÊN)
  Widget _buildSensitivitySlider(BuildContext context, double baselineNoise) {
    return Column(
      children: [
        const Text("Hiệu chỉnh Độ nhạy (Lọc nhiễu nền)"),
        Slider(
          value: baselineNoise,
          min: 0.0,
          max: 150.0, // Giới hạn max
          divisions: 150,
          label: baselineNoise.toStringAsFixed(0),
          activeColor: Colors.red, // Màu của thanh trượt
          onChanged: (newValue) {
            // Gửi sự kiện đến BLoC khi kéo
            context.read<MagneticScannerBloc>().add(
              BaselineNoiseChanged(newValue),
            );
          },
        ),
        TextButton(
          child: const Text(
            "Reset Độ nhạy",
            style: TextStyle(color: Colors.white70),
          ),
          onPressed: () {
            // Đặt lại về 0
            context.read<MagneticScannerBloc>().add(
              const BaselineNoiseChanged(0.0),
            );
          },
        ),
      ],
    );
  }
}
