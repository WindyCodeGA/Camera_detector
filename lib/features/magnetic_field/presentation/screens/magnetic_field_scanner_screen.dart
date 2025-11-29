import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../../application/magnetic_scanner_bloc.dart';
import '../widgets/magnetic_gauge.dart';
import '../../../history/application/history_bloc.dart';
import '../../../history/data/scan_record_model.dart';

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
    _initAudio();
  }

  @override
  void dispose() {
    _isDisposed = true;
    context.read<MagneticScannerBloc>().add(MagneticScanStopped());
    _feedbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      if (!_isDisposed) setState(() => _isBeepLoaded = true);
    } catch (_) {}
  }

  void _triggerFeedback(double val) {
    if (_isDisposed) return;
    _feedbackTimer?.cancel();
    Duration? interval;
    if (val > 250) {
      interval = const Duration(milliseconds: 100);
    } else if (val > 30) {
      interval = const Duration(milliseconds: 200);
    } else if (val > 10) {
      interval = const Duration(milliseconds: 700);
    }

    if (interval != null && _isBeepLoaded) {
      _feedbackTimer = Timer.periodic(interval, (_) async {
        if (_isDisposed) {
          _feedbackTimer?.cancel();
          return;
        }
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        } catch (_) {}
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 50);
        }
      });
    }
  }

  void _saveToHistory(double value) {
    String note = "Normal level";
    if (value > 250) {
      note = "Large Magnet/Metal";
    } else if (value > 30) {
      note = "Danger (Possibly Camera)";
    }
    final record = ScanRecord(
      type: ScanType.magnetic,
      timestamp: DateTime.now(),
      value: "${value.toStringAsFixed(1)} µT",
      note: note,
    );
    context.read<HistoryBloc>().add(AddHistoryRecord(record));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Saved to History!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MagneticScannerBloc, MagneticScannerState>(
      listenWhen: (p, c) =>
          p.displayedValue != c.displayedValue || p.status != c.status,
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
            return Center(child: Text("Lỗi: ${state.errorMessage}"));
          }

          bool isScanning = state.status == MagneticScannerStatus.scanning;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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

                // Đồng hồ & Cảnh báo
                Column(
                  children: [
                    MagneticGauge(value: state.displayedValue, maximum: 2000.0),
                    const SizedBox(height: 10),
                    _buildWarningMessage(state.displayedValue),
                  ],
                ),

                // Thanh trượt
                Column(
                  children: [
                    const Text("Adjust sensitivity"),
                    Slider(
                      value: state.baselineNoise,
                      min: 0,
                      max: 150,
                      divisions: 150,
                      activeColor: Colors.red,
                      onChanged: (v) => context.read<MagneticScannerBloc>().add(
                        BaselineNoiseChanged(v),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<MagneticScannerBloc>().add(
                        const BaselineNoiseChanged(0.0),
                      ),
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),

                // Nút bấm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning ? Colors.red : Colors.green,
                        minimumSize: const Size(120, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => context.read<MagneticScannerBloc>().add(
                        isScanning
                            ? MagneticScanStopped()
                            : MagneticScanStarted(),
                      ),
                      child: Text(
                        isScanning ? "Stop" : "Start",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(120, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: isScanning
                          ? () => _saveToHistory(state.displayedValue)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget hiển thị cảnh báo
  Widget _buildWarningMessage(double value) {
    if (value > 250) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 1),
        ),
        child: const Column(
          children: [
            Icon(Icons.warning, color: Colors.purpleAccent, size: 30),
            SizedBox(height: 4),
            Text(
              "NOT ELECTRONIC CIRCUIT!",
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "This is a large Magnet or Metal.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    // Thêm cảnh báo nhẹ cho mức nguy hiểm thường
    else if (value > 30) {
      return const Text(
        "⚠️ Detects strong magnetic fields\n(Could be an electronic device)",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );
    }
    return const SizedBox.shrink();
  }
}
