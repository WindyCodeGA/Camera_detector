import 'dart:async';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:logger/logger.dart';

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  bool _isFlashlightOn = false;
  bool _isScanning = false;
  int _reflectionsDetected = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _turnOffFlashlight();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        _animationController.reverse();
      } else {
        await TorchLight.enableTorch();
        _animationController.forward();
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Flashlight error: $e')));
      }
    }
  }

  Future<void> _turnOffFlashlight() async {
    if (_isFlashlightOn) {
      try {
        await TorchLight.disableTorch();
        setState(() {
          _isFlashlightOn = false;
        });
      } catch (e) {
        logger.e('Lỗi khi tắt đèn pin: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('lỗi khi tắt đèn pin: $e')));
        }
      }
    }
  }

  Future<void> _startScanning() async {
    if (!_isFlashlightOn) {
      await _toggleFlashlight();
    }

    setState(() {
      _isScanning = true;
      _reflectionsDetected = 0;
    });

    // Simulate camera reflection detection
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }

      // Simulate random reflections
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (random < 20) {
        // 20% chance to detect reflection
        setState(() {
          _reflectionsDetected++;
        });
      }

      // Stop after 10 seconds
      if (timer.tick >= 10) {
        timer.cancel();
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Detection')),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Text(
                  'Camera Detection Instructions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Turn off room lights\n'
                  '2. Turn on flashlight\n'
                  '3. Slowly scan the area\n'
                  '4. Look for bright reflections',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Flashlight control
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isFlashlightOn
                              ? Colors.yellow.withAlpha((0.8 * 255).round())
                              : Colors.grey.withAlpha((0.3 * 255).round()),
                          boxShadow: _isFlashlightOn
                              ? [
                                  BoxShadow(
                                    color: Colors.yellow.withAlpha(
                                      (0.3 * 255).round(),
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleFlashlight,
                            borderRadius: BorderRadius.circular(75),
                            child: Center(
                              child: Icon(
                                _isFlashlightOn
                                    ? Icons.flashlight_on
                                    : Icons.flashlight_off,
                                size: 60,
                                color: _isFlashlightOn
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    _isFlashlightOn ? 'Flashlight ON' : 'Flashlight OFF',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (_isScanning)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning... Reflections: $_reflectionsDetected',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                  if (!_isScanning && _reflectionsDetected > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.8 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'Warning: $_reflectionsDetected potential camera reflections detected!',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startScanning,
                    child: Text(
                      _isScanning ? 'Scanning...' : 'Start Camera Scan',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleFlashlight,
                        icon: Icon(
                          _isFlashlightOn
                              ? Icons.flashlight_on
                              : Icons.flashlight_off,
                        ),
                        label: Text(_isFlashlightOn ? 'Turn Off' : 'Turn On'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFlashlightOn
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
