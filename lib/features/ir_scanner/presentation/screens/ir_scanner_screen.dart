import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

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
    // Yêu cầu BLoC khởi tạo camera ngay khi vào màn hình
    context.read<IrScannerBloc>().add(IrCameraInitialize());
  }

  // Hàm helper để tạo ColorFilter dựa trên enum
  ColorFilter? _getColorFilter(IRFilter filter) {
    switch (filter) {
      case IRFilter.red:
        return ColorFilter.mode(
          Colors.red.withAlpha((255 * 0.5).round()),
          BlendMode.modulate,
        );
      case IRFilter.green:
        return ColorFilter.mode(
          Colors.green.withAlpha((255 * 0.5).round()),
          BlendMode.modulate,
        );
      case IRFilter.blue:
        return ColorFilter.mode(
          Colors.blue.withAlpha((255 * 0.5).round()),
          BlendMode.modulate,
        );
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
        return null; // Không áp dụng bộ lọc
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infrared Scan1'),
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
          // Dùng listener để hiển thị lỗi
          if (state.status == IrScannerStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Hiển thị loading
          if (state.status == IrScannerStatus.loading ||
              state.status == IrScannerStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hiển thị camera preview
          if (state.status == IrScannerStatus.ready ||
              state.status == IrScannerStatus.recording) {
            final controller = state.cameraController;
            if (controller == null) {
              return const Center(child: Text("Camera không khả dụng."));
            }

            // Tính toán tỷ lệ
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

                // Nút Quay video (chỉ là ví dụ, chưa ẩn)
                // Bạn có thể thêm nút quay video ở đây
                // Ví dụ:
                // Positioned(
                //   bottom: 180,
                //   left: MediaQuery.of(context).size.width / 2 - 25,
                //   child: _buildRecordButton(context, state.isRecording),
                // ),

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

          // Hiển thị lỗi
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(state.errorMessage ?? "Đã xảy ra lỗi không xác định."),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    context.read<IrScannerBloc>().add(IrCameraInitialize());
                  },
                  child: const Text("Thử lại"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget cho nút Flash
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
              : Colors.white.withAlpha((255 * 0.8).round()),
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

  // Widget cho nút Filter
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
