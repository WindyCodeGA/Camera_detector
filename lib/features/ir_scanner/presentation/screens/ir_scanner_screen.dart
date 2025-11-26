import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// Import BLoC, Event, State
import '../../application/ir_scanner_bloc.dart';

class IRScannerScreen extends StatefulWidget {
  const IRScannerScreen({super.key});

  @override
  State<IRScannerScreen> createState() => _IRScannerScreenState();
}

class _IRScannerScreenState extends State<IRScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Gửi sự kiện khởi tạo ngay lập tức
    // BLoC sẽ tự kiểm tra xem đã có quyền chưa
    context.read<IrScannerBloc>().add(IrCameraInitialize());
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted && mounted) {
      // Nếu được cấp quyền, thử khởi tạo lại
      context.read<IrScannerBloc>().add(IrCameraInitialize());
    } else if (status.isPermanentlyDenied && mounted) {
      // Nếu bị từ chối vĩnh viễn, mở cài đặt
      openAppSettings();
    }
  }

  // Helper tạo bộ lọc (Giữ nguyên)
  ColorFilter? _getColorFilter(IRFilter filter) {
    switch (filter) {
      case IRFilter.red:
        return ColorFilter.mode(Colors.red.withAlpha(128), BlendMode.modulate);
      case IRFilter.green:
        return ColorFilter.mode(
          Colors.green.withAlpha(128),
          BlendMode.modulate,
        );
      case IRFilter.blue:
        return ColorFilter.mode(Colors.blue.withAlpha(128), BlendMode.modulate);
      case IRFilter.greyscale:
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case IRFilter.normal:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infrared Scan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              /* Navigate to settings */
            },
          ),
        ],
      ),
      body: BlocConsumer<IrScannerBloc, IrScannerState>(
        listener: (context, state) {
          // Chỉ hiện SnackBar cho các lỗi KHÁC lỗi quyền
          if (state.status == IrScannerStatus.error &&
              state.errorMessage != null &&
              state.errorMessage != "PERMISSION_DENIED") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // 1. Loading
          if (state.status == IrScannerStatus.loading ||
              state.status == IrScannerStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Xử lý lỗi: CHƯA CÓ QUYỀN (PERMISSION_DENIED)
          // Đây là nơi chúng ta thay thế cho _permissionStatus.denied
          if (state.status == IrScannerStatus.error &&
              state.errorMessage == "PERMISSION_DENIED") {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Cần quyền Camera để quét hồng ngoại.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Vui lòng cấp quyền để sử dụng tính năng này.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _requestPermission, // Gọi hàm xin quyền
                      child: const Text("Cho phép truy cập"),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Xử lý lỗi KHÁC (Ví dụ: không tìm thấy camera)
          if (state.status == IrScannerStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(state.errorMessage ?? "Lỗi không xác định"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<IrScannerBloc>().add(IrCameraInitialize()),
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          // 4. Camera Ready (Thành công)
          if ((state.status == IrScannerStatus.ready ||
                  state.status == IrScannerStatus.recording) &&
              state.cameraController != null) {
            final controller = state.cameraController!;

            // Tính toán tỷ lệ (như code cũ)
            final mediaSize = MediaQuery.of(context).size;
            final scale = mediaSize.aspectRatio * controller.value.aspectRatio;
            final actualScale = scale < 1 ? 1 / scale : scale;

            return Stack(
              children: [
                // Camera Preview
                Positioned.fill(
                  child: Transform.scale(
                    scale: actualScale,
                    alignment: Alignment.center,
                    child: ColorFiltered(
                      colorFilter:
                          _getColorFilter(state.currentFilter) ??
                          const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          ),
                      child: CameraPreview(controller),
                    ),
                  ),
                ),

                // Nút Flashlight
                Positioned(
                  bottom: 120,
                  left: MediaQuery.of(context).size.width / 2 - 25,
                  child: _buildFlashButton(context, state.isFlashlightOn),
                ),

                // Các nút chọn bộ lọc
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterButton(
                        context,
                        state.currentFilter,
                        IRFilter.normal,
                        Colors.white,
                        Icons.circle,
                        "Normal",
                      ),
                      _buildFilterButton(
                        context,
                        state.currentFilter,
                        IRFilter.red,
                        Colors.red,
                        Icons.circle,
                        "Red",
                      ),
                      _buildFilterButton(
                        context,
                        state.currentFilter,
                        IRFilter.green,
                        Colors.green,
                        Icons.circle,
                        "Green",
                      ),
                      _buildFilterButton(
                        context,
                        state.currentFilter,
                        IRFilter.blue,
                        Colors.blue,
                        Icons.circle,
                        "Blue",
                      ),
                      _buildFilterButton(
                        context,
                        state.currentFilter,
                        IRFilter.greyscale,
                        Colors.grey,
                        Icons.nights_stay,
                        "B/W",
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Fallback
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Widget Helper: Flash Button (Giữ nguyên)
  Widget _buildFlashButton(BuildContext context, bool isFlashlightOn) {
    return GestureDetector(
      onTap: () {
        context.read<IrScannerBloc>().add(IrFlashlightToggled());
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isFlashlightOn
              ? Colors.yellow.shade700
              : Colors.white.withAlpha(204), // 204 ~ 0.8
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          isFlashlightOn ? Icons.flash_on : Icons.flash_off,
          color: isFlashlightOn ? Colors.white : Colors.black,
          size: 28,
        ),
      ),
    );
  }

  // Widget Helper: Filter Button (Giữ nguyên)
  Widget _buildFilterButton(
    BuildContext context,
    IRFilter currentFilter,
    IRFilter filter,
    Color color,
    IconData icon,
    String label,
  ) {
    final isSelected = currentFilter == filter;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.read<IrScannerBloc>().add(IrFilterChanged(filter));
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withAlpha(isSelected ? 255 : 153),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
