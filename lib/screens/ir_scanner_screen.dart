import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:logger/logger.dart';

class IRScannerScreen extends StatefulWidget {
  const IRScannerScreen({super.key});

  @override
  State<IRScannerScreen> createState() => _IRScannerScreenState();
}

class _IRScannerScreenState extends State<IRScannerScreen>
    with WidgetsBindingObserver {
  final logger = Logger();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  int _irPointsDetected = 0;
  List<Offset> _irPoints = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();

      // Use front camera for IR detection
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final cameraToUse = frontCamera ?? _cameras!.first;

      _controller = CameraController(
        cameraToUse,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      logger.e('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      setState(() {
        _isScanning = false;
        _showResults = true;
      });
    } else {
      setState(() {
        _isScanning = true;
        _showResults = false;
        _irPoints = [];
        _irPointsDetected = 0;
      });

      // Simulate IR detection
      _simulateIRDetection();
    }
  }

  void _simulateIRDetection() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }

      // Simulate random IR points
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (random < 30) {
        // 30% chance to detect IR
        final newPoints = <Offset>[];
        for (int i = 0; i < (random % 3) + 1; i++) {
          newPoints.add(
            Offset(
              (random * 7 + i * 13) % 100 / 100.0,
              (random * 11 + i * 17) % 100 / 100.0,
            ),
          );
        }

        if (newPoints.isNotEmpty && _irPoints.isEmpty) {
          _vibrate();
        }

        setState(() {
          _irPoints = newPoints;
          _irPointsDetected = newPoints.length;
        });
      }
    });
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('IR Scanner')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('IR Scanner')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreview(_controller!),

                // Green overlay
                Container(color: Colors.green.withAlpha((0.3 * 255).round())),

                // IR points overlay
                CustomPaint(
                  painter: IRPointsPainter(
                    irPoints: _irPoints,
                    screenSize: MediaQuery.of(context).size,
                  ),
                ),

                // Status overlay
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(((0.7 * 255).round())),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isScanning
                            ? 'Scanning: $_irPointsDetected IR points detected'
                            : 'Ready to scan',
                        style: TextStyle(
                          color: _irPointsDetected > 0
                              ? Colors.red
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Results overlay
                if (_showResults)
                  Container(
                    color: Colors.black.withAlpha((0.8 * 255).round()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Scan Results',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Detected $_irPointsDetected IR points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_irPointsDetected > 0)
                          const Text(
                            '⚠️ Potential hidden cameras detected!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showResults = false;
                            });
                          },
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Control button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: ElevatedButton(
              onPressed: _toggleScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isScanning ? 'STOP SCAN' : 'START SCAN',
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

class IRPointsPainter extends CustomPainter {
  final List<Offset> irPoints;
  final Size screenSize;

  IRPointsPainter({required this.irPoints, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var point in irPoints) {
      final screenX = point.dx * size.width;
      final screenY = point.dy * size.height;

      canvas.drawCircle(Offset(screenX, screenY), 8, paint);

      // Draw crosshair
      canvas.drawLine(
        Offset(screenX - 15, screenY),
        Offset(screenX + 15, screenY),
        paint..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(screenX, screenY - 15),
        Offset(screenX, screenY + 15),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IRPointsPainter oldDelegate) {
    return oldDelegate.irPoints != irPoints;
  }
}
