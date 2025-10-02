import 'package:isar/isar.dart';

part 'keyset_info.g.dart';

/// Keyset information model for Isar database
@collection
class KeysetInfo {
  KeysetInfo({
    required this.keysetId,
    required this.mintURL,
    required this.unit,
    required this.active,
    required this.firstSeen,
    required this.lastSeen,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String keysetId;

  late String mintURL;
  late String unit;
  late bool active;
  late int firstSeen;
  late int lastSeen;

  /// Create from server response
  factory KeysetInfo.fromServerMap(Map<String, dynamic> map, String mintURL) {
    return KeysetInfo(
      keysetId: map['id']?.toString() ?? '',
      mintURL: mintURL,
      unit: map['unit']?.toString() ?? 'sat',
      active: map['active'] ?? true,
      firstSeen: map['first_seen'] ?? 0,
      lastSeen: map['last_seen'] ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': keysetId,
    'unit': unit,
    'active': active,
    'first_seen': firstSeen,
    'last_seen': lastSeen,
  };

  @override
  String toString() {
    return 'KeysetInfo(keysetId: $keysetId, mintURL: $mintURL, unit: $unit, active: $active)';
  }
}
