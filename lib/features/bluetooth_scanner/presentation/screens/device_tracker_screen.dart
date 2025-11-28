import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import Model
import '../../models/bluetooth_device_model.dart';

// Import History (Để lưu kết quả)
import '../../../history/application/history_bloc.dart';
import '../../../history/data/scan_record_model.dart';

class DeviceTrackerScreen extends StatefulWidget {
  final BluetoothDeviceModel deviceModel;
  const DeviceTrackerScreen({super.key, required this.deviceModel});

  @override
  State<DeviceTrackerScreen> createState() => _DeviceTrackerScreenState();
}

class _DeviceTrackerScreenState extends State<DeviceTrackerScreen> {
  StreamSubscription<List<ScanResult>>? _stream;

  // Dữ liệu tín hiệu
  int _targetRssi = -100; // Giá trị thực (cập nhật liên tục)
  double _displayRssi = -100.0; // Giá trị hiển thị (làm mượt animation)

  final AudioPlayer _player = AudioPlayer();
  Timer? _beepTimer;
  Timer? _smoothTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Lấy RSSI ban đầu từ model truyền sang
    _targetRssi = widget.deviceModel.scanResult.rssi;
    _displayRssi = _targetRssi.toDouble();

    _initAudio();
    _startRealtimeScan(); // Bắt đầu quét lại ngay lập tức
    _startSmoothAnimation(); // Chạy animation mượt
    _updateBeepSpeed(); // Bắt đầu âm thanh
  }

  Future<void> _initAudio() async {
    try {
      await _player.setSource(AssetSource('sounds/beep.mp3'));
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  // Timer làm mượt số liệu (Animation loop)
  void _startSmoothAnimation() {
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed) return;
      // Di chuyển giá trị hiển thị dần dần tới giá trị thực
      if ((_displayRssi - _targetRssi).abs() > 0.5) {
        setState(() {
          _displayRssi += (_targetRssi - _displayRssi) * 0.15;
        });
      }
    });
  }

  void _startRealtimeScan() async {
    // 1. Dừng quét cũ (nếu có) để tránh xung đột
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    // 2. Bắt đầu quét chế độ Low Latency (Độ trễ thấp - Quét nhanh)
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 10), // Quét lâu
        androidUsesFineLocation: true,
        androidScanMode:
            AndroidScanMode.lowLatency, // Quan trọng: Quét liên tục
        continuousUpdates: true, // Quan trọng cho iOS
      );
    } catch (e) {
      debugPrint("Lỗi quét Tracker: $e");
    }

    // 3. Lắng nghe và lọc đúng thiết bị này
    _stream = FlutterBluePlus.scanResults.listen((results) {
      if (_isDisposed) return;
      try {
        final found = results.firstWhere(
          (r) =>
              r.device.remoteId ==
              widget.deviceModel.scanResult.device.remoteId,
        );
        // Cập nhật giá trị đích
        _targetRssi = found.rssi;
        _updateBeepSpeed();
      } catch (_) {
        // Không tìm thấy trong lần quét này (có thể do sóng chập chờn)
      }
    });
  }

  // Điều chỉnh tốc độ bíp dựa trên khoảng cách
  void _updateBeepSpeed() {
    _beepTimer?.cancel();
    if (_isDisposed) return;

    // Nếu tín hiệu quá yếu (-90), không kêu
    if (_targetRssi < -95) return;

    // Tính toán interval: -90dBm (xa) -> 2000ms, -40dBm (gần) -> 200ms
    int interval = (2000 - ((_targetRssi + 95) * 40)).clamp(200, 2000);

    _beepTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      _playBeep();
    });
  }

  void _playBeep() async {
    if (_isDisposed) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.mp3'), volume: 0.6);

      // Rung nếu ở khá gần (> -70dBm)
      if (_targetRssi > -70) {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 100);
        }
      }
    } catch (_) {}
  }

  // --- LOGIC LƯU LỊCH SỬ ---
  void _saveFoundDevice() {
    // 1. Tạo bản ghi
    final record = ScanRecord(
      type: ScanType.bluetooth,
      timestamp: DateTime.now(),
      value: "${widget.deviceModel.name} ($_targetRssi dBm)",
      note: "Đã tìm thấy ở khoảng cách ${_getDistance(_targetRssi.toDouble())}",
    );

    // 2. Gửi sang HistoryBloc
    context.read<HistoryBloc>().add(AddHistoryRecord(record));

    // 3. Thông báo và thoát
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã lưu vị trí vào Lịch sử!"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context); // Quay về danh sách sau khi tìm thấy
  }

  @override
  void dispose() {
    _isDisposed = true;
    FlutterBluePlus.stopScan(); // Dừng quét ngay lập tức
    _stream?.cancel();
    _beepTimer?.cancel();
    _smoothTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  // Công thức ước tính khoảng cách
  String _getDistance(double rssi) {
    if (rssi == 0) return "Unknown";
    int txPower = -59; // Giả định công suất phát chuẩn
    double ratio = (txPower - rssi) / 20.0;
    double dist = pow(10, ratio).toDouble();

    if (dist < 1.0) return "${(dist * 100).toStringAsFixed(0)} cm";
    return "${dist.toStringAsFixed(1)} m";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán độ mạnh tín hiệu (0.0 -> 1.0) để đổi màu và kích thước
    double signalStrength = ((_displayRssi + 100) / 60).clamp(0.0, 1.0);

    // Đổi màu: Xanh (Xa) -> Đỏ (Gần)
    Color color = Color.lerp(Colors.green, Colors.red, signalStrength)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Device Tracker"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tên thiết bị
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.deviceModel.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              widget.deviceModel.scanResult.device.remoteId.str,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const Spacer(),

            // --- RADAR ANIMATION ---
            Stack(
              alignment: Alignment.center,
              children: [
                // Vòng lan tỏa (Pulse)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 200 + (150 * signalStrength), // To ra khi lại gần
                  height: 200 + (150 * signalStrength),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2), // Mờ
                  ),
                ),
                // Vòng tròn chính
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 6),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_displayRssi.toStringAsFixed(0)} dBm",
                        style: TextStyle(
                          fontSize: 40,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getDistance(_displayRssi),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Trạng thái văn bản
            Text(
              signalStrength > 0.85
                  ? "RẤT GẦN! HÃY TÌM KỸ"
                  : signalStrength > 0.5
                  ? "ĐANG LẠI GẦN..."
                  : "TÍN HIỆU YẾU / XA",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 30),

            // Nút "Found It" (Lưu lịch sử)
            ElevatedButton.icon(
              onPressed: _saveFoundDevice,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                "Đánh dấu đã tìm thấy",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
