import 'package:flutter/material.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkDevicesScreen extends StatefulWidget {
  final String ssid;
  const NetworkDevicesScreen({super.key, required this.ssid});

  @override
  State<NetworkDevicesScreen> createState() => _NetworkDevicesScreenState();
}

class _NetworkDevicesScreenState extends State<NetworkDevicesScreen> {
  final List<Host> _devices = [];
  bool _isScanning = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _scanLan();
  }

  Future<void> _scanLan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _progress = 0.0;
    });

    final scanner = LanScanner();
    final info = NetworkInfo();

    // 1. Lấy IP của chính mình (ví dụ: 192.168.1.5)
    final String? wifiIp = await info.getWifiIP();
    final String? subnet = ipToSubnet(wifiIp ?? '');

    if (subnet == null) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không lấy được địa chỉ IP nội bộ.")),
        );
      }
      return;
    }

    // 2. Bắt đầu quét từ .1 đến .255
    final stream = scanner.icmpScan(
      subnet,
      progressCallback: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    stream.listen(
      (Host host) {
        if (mounted) {
          setState(() {
            _devices.add(host);
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thiết bị trong mạng", style: TextStyle(fontSize: 18)),
            Text(
              widget.ssid,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (_isScanning)
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _progress,
                color: Colors.white,
              ),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _scanLan),
        ],
      ),
      body: Column(
        children: [
          // Thanh trạng thái
          if (_isScanning)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[800],
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tìm thấy: ${_devices.length} thiết bị",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách thiết bị
          Expanded(
            child: _devices.isEmpty && !_isScanning
                ? const Center(child: Text("Không tìm thấy thiết bị nào khác."))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.computer, color: Colors.white),
                          ),
                          title: Text(device.internetAddress.address),
                          subtitle: Text(
                            "Phản hồi: ${device.pingTime ?? 'N/A'} ms",
                          ),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String? ipToSubnet(String ip) {
    if (ip.isEmpty) return null;
    final List<String> parts = ip.split('.');
    if (parts.length < 3) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }
}
