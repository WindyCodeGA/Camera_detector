import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// Import BLoC hồng ngoại
import '../../application/ir_scanner_bloc.dart';

// --- THÊM IMPORT CHO HISTORY (LỊCH SỬ) ---
// (Lưu ý: Đảm bảo đường dẫn này đúng với cấu trúc thư mục của bạn)
import '../../../history/application/history_bloc.dart';
import '../../../history/data/scan_record_model.dart';

class IRScannerScreen extends StatefulWidget {
  const IRScannerScreen({super.key});

  @override
  State<IRScannerScreen> createState() => _IRScannerScreenState();
}

class _IRScannerScreenState extends State<IRScannerScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<IrScannerBloc>().add(IrCameraInitialize());
      }
    });
  }

  Future<void> _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted && mounted) {
      context.read<IrScannerBloc>().add(IrCameraInitialize());
    } else if (statuses[Permission.camera]!.isPermanentlyDenied && mounted) {
      openAppSettings();
    }
  }

  ColorFilter? _getColorFilter(IRFilter filter) {
    switch (filter) {
      case IRFilter.red:
        // Lọc chỉ giữ lại kênh Đỏ, loại bỏ Xanh lá và Xanh dương
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0, // R = 1*R
          0, 0, 0, 0, 0, // G = 0
          0, 0, 0, 0, 0, // B = 0
          0, 0, 0, 1, 0, // Alpha giữ nguyên
        ]);

      case IRFilter.green:
        return const ColorFilter.matrix([
          0, 0, 0, 0, 0,
          0, 1, 0, 0, 0, // Chỉ giữ Green
          0, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
        ]);

      case IRFilter.blue:
        return const ColorFilter.matrix([
          0, 0, 0, 0, 0,
          0, 0, 0, 0, 0,
          0, 0, 1, 0, 0, // Chỉ giữ Blue
          0, 0, 0, 1, 0,
        ]);

      case IRFilter.greyscale:
        // Giữ nguyên bộ lọc đen trắng cũ của bạn (nó đã tốt rồi)
        return const ColorFilter.matrix([
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Infrared Camera'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: BlocConsumer<IrScannerBloc, IrScannerState>(
        listenWhen: (prev, curr) =>
            prev.lastRecordedVideo != curr.lastRecordedVideo ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          // 1. Xử lý lỗi
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

          // 2. KHI LƯU VIDEO THÀNH CÔNG -> LƯU VÀO LỊCH SỬ
          if (state.lastRecordedVideo != null) {
            // --- LOGIC MỚI: LƯU VÀO HISTORY ---
            final record = ScanRecord(
              type: ScanType.infrared, // Loại quét: Hồng ngoại
              timestamp: DateTime.now(),
              value: "Đã quay video hồng ngoại",
              note: state
                  .lastRecordedVideo!
                  .path, // Lưu đường dẫn file để sau này mở lại
            );

            // Gửi sự kiện sang HistoryBloc
            context.read<HistoryBloc>().add(AddHistoryRecord(record));
            // ----------------------------------

            // Hiện thông báo cho người dùng
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đã lưu video vào Thư viện & Lịch sử!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == IrScannerStatus.loading ||
              state.status == IrScannerStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == IrScannerStatus.error &&
              state.errorMessage == "PERMISSION_DENIED") {
            return _buildPermissionDeniedUI();
          }

          if ((state.status == IrScannerStatus.ready ||
                  state.status == IrScannerStatus.recording) &&
              state.cameraController != null) {
            return _buildCameraUI(context, state);
          }

          return Center(
            child: ElevatedButton(
              onPressed: () =>
                  context.read<IrScannerBloc>().add(IrCameraInitialize()),
              child: const Text("Thử lại"),
            ),
          );
        },
      ),
    );
  }

  // --- CÁC WIDGET CON (GIỮ NGUYÊN) ---

  Widget _buildCameraUI(BuildContext context, IrScannerState state) {
    final controller = state.cameraController!;
    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * controller.value.aspectRatio;
    final actualScale = scale < 1 ? 1 / scale : scale;

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: actualScale,
            alignment: Alignment.center,
            child: ColorFiltered(
              colorFilter:
                  _getColorFilter(state.currentFilter) ??
                  const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
              child: CameraPreview(controller),
            ),
          ),
        ),

        Positioned(
          top: 20,
          right: 20,
          child: _buildFlashButton(context, state.isFlashlightOn),
        ),

        if (state.isRecording)
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8), // ~0.8
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "REC",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRecordButton(context, state.isRecording),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton(
                    context,
                    state.currentFilter,
                    IRFilter.normal,
                    Colors.white,
                    "Normal",
                  ),
                  _buildFilterButton(
                    context,
                    state.currentFilter,
                    IRFilter.red,
                    Colors.red,
                    "Red",
                  ),
                  _buildFilterButton(
                    context,
                    state.currentFilter,
                    IRFilter.green,
                    Colors.green,
                    "Green",
                  ),
                  _buildFilterButton(
                    context,
                    state.currentFilter,
                    IRFilter.blue,
                    Colors.blue,
                    "Blue",
                  ),
                  _buildFilterButton(
                    context,
                    state.currentFilter,
                    IRFilter.greyscale,
                    Colors.grey,
                    "B/W",
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton(BuildContext context, bool isRecording) {
    return GestureDetector(
      onTap: () {
        if (isRecording) {
          context.read<IrScannerBloc>().add(IrVideoRecordingStopped());
        } else {
          context.read<IrScannerBloc>().add(IrVideoRecordingStarted());
        }
      },
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 35 : 65,
            height: isRecording ? 35 : 65,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(isRecording ? 6 : 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashButton(BuildContext context, bool isFlashlightOn) {
    return GestureDetector(
      onTap: () => context.read<IrScannerBloc>().add(IrFlashlightToggled()),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isFlashlightOn ? Colors.yellow.shade700 : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          isFlashlightOn ? Icons.flash_on : Icons.flash_off,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    IRFilter currentFilter,
    IRFilter filter,
    Color color,
    String label,
  ) {
    final isSelected = currentFilter == filter;
    return GestureDetector(
      onTap: () => context.read<IrScannerBloc>().add(IrFilterChanged(filter)),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(isSelected ? 255 : 100),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "Cần quyền Camera & Micro",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text("Cho phép"),
          ),
        ],
      ),
    );
  }
}
