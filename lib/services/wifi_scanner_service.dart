import '../models/network_device.dart';

class WifiScannerService {
  Future<List<NetworkDevice>> scanDevices() async {
    // Simulate network scanning delay
    await Future.delayed(const Duration(seconds: 2));

    return [
      NetworkDevice(
        ipAddress: '192.168.1.1',
        macAddress: '00:11:22:33:44:55',
        deviceName: 'Router',
        isSuspicious: false,
      ),
      NetworkDevice(
        ipAddress: '192.168.1.4',
        macAddress: '66:77:88:99:AA:BB',
        deviceName: 'My Device',
        isSuspicious: false,
      ),
      NetworkDevice(
        ipAddress: '192.168.1.5',
        macAddress: 'CC:DD:EE:FF:00:11',
        deviceName: 'Unknown Device',
        isSuspicious: true,
      ),
      NetworkDevice(
        ipAddress: '192.168.1.6',
        macAddress: '22:33:44:55:66:77',
        deviceName: 'Suspicious Camera',
        isSuspicious: true,
      ),
      NetworkDevice(
        ipAddress: '192.168.1.7',
        macAddress: '88:99:AA:BB:CC:DD',
        deviceName: 'Hidden Device',
        isSuspicious: true,
      ),
    ];
  }
}
