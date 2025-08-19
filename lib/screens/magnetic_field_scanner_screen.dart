import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class MagneticFieldScannerScreen extends StatefulWidget {
  const MagneticFieldScannerScreen({super.key});

  @override
  State<MagneticFieldScannerScreen> createState() =>
      _MagneticFieldScannerScreenState();
}

class _MagneticFieldScannerScreenState extends State<MagneticFieldScannerScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  bool _isScanning = false;
  double _currentMagnitude = 0.0;
  double _baselineMagnitude = 0.0;
  double _maxMagnitude = 0.0;
  double _minMagnitude = 0.0;
  final List<double> _magneticHistory = [];

  final double _significantChangeThreshold = 10.0;
  final double _anomalyThreshold = 100.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isAnomalyDetected = false;
  DateTime? _lastAlertTime;
  int _anomalyCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeBaseline();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeBaseline() async {
    List<double> baselineReadings = [];

    final subscription = magnetometerEvents.listen((MagnetometerEvent event) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);
      baselineReadings.add(magnitude);
    });

    await Future.delayed(const Duration(seconds: 2));
    subscription.cancel();

    if (baselineReadings.isNotEmpty) {
      _baselineMagnitude =
          baselineReadings.reduce((a, b) => a + b) / baselineReadings.length;
      _maxMagnitude = _baselineMagnitude;
      _minMagnitude = _baselineMagnitude;
    }

    if (mounted) {
      setState(() {});
    }
  }

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _magneticHistory.clear();
      _anomalyCount = 0;
      _isAnomalyDetected = false;
    });

    _magnetometerSubscription = magnetometerEvents.listen((
      MagnetometerEvent event,
    ) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);

      if (mounted) {
        setState(() {
          _currentMagnitude = magnitude;

          _magneticHistory.add(magnitude);
          if (_magneticHistory.length > 100) {
            _magneticHistory.removeAt(0);
          }

          if (magnitude > _maxMagnitude) _maxMagnitude = magnitude;
          if (magnitude < _minMagnitude) _minMagnitude = magnitude;

          _checkForAnomaly(magnitude);
        });
      }
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    _magnetometerSubscription?.cancel();
  }

  void _checkForAnomaly(double magnitude) {
    final deviation = (magnitude - _baselineMagnitude).abs();

    if (deviation > _anomalyThreshold) {
      if (!_isAnomalyDetected ||
          (_lastAlertTime != null &&
              DateTime.now().difference(_lastAlertTime!).inSeconds > 2)) {
        setState(() {
          _isAnomalyDetected = true;
          _anomalyCount++;
          _lastAlertTime = DateTime.now();
        });

        _triggerAlert();
      }
    } else if (deviation < _significantChangeThreshold) {
      setState(() {
        _isAnomalyDetected = false;
      });
    }
  }

  Future<void> _triggerAlert() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500, amplitude: 255);
    }

    SystemSound.play(SystemSoundType.alert);
  }

  Color _getMagnitudeColor(double magnitude) {
    final deviation = (magnitude - _baselineMagnitude).abs();

    if (deviation > _anomalyThreshold) {
      return Colors.red;
    } else if (deviation > _significantChangeThreshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (!_isScanning) return 'Ready to scan';

    final deviation = (_currentMagnitude - _baselineMagnitude).abs();

    if (deviation > _anomalyThreshold) {
      return 'WARNING: Magnetic anomaly detected!';
    } else if (deviation > _significantChangeThreshold) {
      return 'Magnetic field change detected';
    } else {
      return 'Magnetic field stable';
    }
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Magnetic Field Scanner')),
      body: Column(
        children: [
          // Status section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getMagnitudeColor(
              _currentMagnitude,
            ).withAlpha((0.1 * 255).round()),
            child: Column(
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getMagnitudeColor(_currentMagnitude),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Anomalies detected: $_anomalyCount',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          // Magnetic field visualization
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isScanning ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getMagnitudeColor(
                            _currentMagnitude,
                          ).withAlpha((0.2 * 255).round()),
                          border: Border.all(
                            color: _getMagnitudeColor(_currentMagnitude),
                            width: 3,
                          ),
                          boxShadow: _isAnomalyDetected
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(
                                      (0.5 * 255).round(),
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentMagnitude.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getMagnitudeColor(_currentMagnitude),
                              ),
                            ),
                            Text(
                              'µT',
                              style: TextStyle(
                                fontSize: 16,
                                color: _getMagnitudeColor(_currentMagnitude),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Baseline: ${_baselineMagnitude.toStringAsFixed(1)} µT',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Move your device slowly around the area to detect electronic devices. '
              'Magnetic field changes may indicate hidden cameras or recording devices.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),

          // Control button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isScanning ? _stopScanning : _startScanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isScanning ? 'STOP SCANNING' : 'START SCANNING',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
