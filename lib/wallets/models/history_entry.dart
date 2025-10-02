import 'package:isar/isar.dart';

part 'history_entry.g.dart';

/// Transaction history type enum
enum HistoryType {
  unknown(0),
  eCash(1),
  lnInvoice(2),
  multiMintSwap(3),
  swapForP2PK(4);

  const HistoryType(this.value);
  final int value;

  static HistoryType fromValue(dynamic value) =>
      HistoryType.values.where((element) => element.value == value).firstOrNull ?? HistoryType.unknown;
}

/// Transaction history entry model for Isar database
@collection
class HistoryEntry {
  HistoryEntry({
    required this.amount,
    required this.typeRaw,
    required this.timestamp,
    required this.value,
    required this.mints,
    this.fee,
    this.isSpent,
    this.memo = '',
  });

  Id id = Isar.autoIncrement;

  /// Transaction amount in satoshis
  late double amount;

  /// Transaction type as integer
  late int typeRaw;

  /// Get transaction type enum
  @ignore
  HistoryType get type => HistoryType.fromValue(typeRaw);

  /// Unix timestamp
  late double timestamp;

  /// Payment key (Lightning invoice) or encoded Cashu token
  late String value;

  /// Mints involved in the transaction
  late List<String> mints;

  /// Transaction fee (optional)
  int? fee;

  /// Whether the token is spent (for eCash transactions)
  bool? isSpent;

  /// Transaction memo/description
  late String memo;

  /// Create from transaction data
  factory HistoryEntry.fromTransaction({
    required double amount,
    required HistoryType type,
    required String value,
    required List<String> mints,
    int? fee,
    bool? isSpent,
    String memo = '',
  }) {
    return HistoryEntry(
      amount: amount,
      typeRaw: type.value,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      value: value,
      mints: mints,
      fee: fee,
      isSpent: isSpent,
      memo: memo,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': typeRaw,
    'timestamp': timestamp,
    'value': value,
    'mints': mints,
    if (fee != null) 'fee': fee,
    if (isSpent != null) 'isSpent': isSpent,
    'memo': memo,
  };

  @override
  String toString() {
    return 'HistoryEntry(id: $id, amount: $amount, type: $type, timestamp: $timestamp, memo: $memo)';
  }
}
