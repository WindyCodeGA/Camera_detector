class NetworkDevice {
  final String ipAddress;
  final String macAddress;
  final String deviceName;
  final bool isSuspicious;

  NetworkDevice({
    required this.ipAddress,
    required this.macAddress,
    required this.deviceName,
    this.isSuspicious = false,
  });
}
