enum ScanType { infrared, magnetic, wifi, bluetooth }

class ScanRecord {
  final int? id;
  final ScanType type;
  final DateTime timestamp;
  final String value;
  final String? note;

  ScanRecord({
    this.id,
    required this.type,
    required this.timestamp,
    required this.value,
    this.note,
  });

  // Chuyển đổi để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'note': note,
    };
  }

  // Chuyển đổi từ SQLite ra Object
  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'],
      type: ScanType.values[map['type']],
      timestamp: DateTime.parse(map['timestamp']),
      value: map['value'],
      note: map['note'],
    );
  }
}
