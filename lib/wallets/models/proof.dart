import 'package:isar/isar.dart';

part 'proof.g.dart';

/// Cashu Proof model for Isar database
@collection
class Proof {
  Proof({
    required this.keysetId,
    required this.amount,
    required this.secret,
    required this.C,
    this.witness = '',
    this.dleqPlainText = '',
  });

  Id id = Isar.autoIncrement;

  /// Keyset id, used to link proofs to a mint and its keys
  @Index(composite: [CompositeIndex('secret')], unique: true)
  late String keysetId;

  /// Amount denominated in Satoshis
  late String amount;

  /// The initial secret that was randomly chosen for the creation of this proof
  late String secret;

  /// The unblinded signature for this secret, signed by the mint's private key
  late String C;

  /// Witness data (optional)
  late String witness;

  /// DLEQ proof data (JSON string)
  late String dleqPlainText;

  /// Get amount as integer
  int get amountNum => int.tryParse(amount) ?? 0;

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() => {
    'id': keysetId,
    'amount': amountNum,
    'secret': secret,
    'C': C,
    if (witness.isNotEmpty) 'witness': witness,
  };

  /// Create from server JSON response
  factory Proof.fromServerJson(Map<String, dynamic> map) {
    return Proof(
      keysetId: map['id']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '0',
      secret: map['secret']?.toString() ?? '',
      C: map['C']?.toString() ?? '',
      witness: map['witness']?.toString() ?? '',
      dleqPlainText: map['dleq'] != null ? map['dleq'].toString() : '',
    );
  }

  /// Create from map
  factory Proof.fromMap(Map<String, dynamic> map) {
    return Proof(
      keysetId: map['keysetId']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '0',
      secret: map['secret']?.toString() ?? '',
      C: map['C']?.toString() ?? '',
      witness: map['witness']?.toString() ?? '',
      dleqPlainText: map['dleqPlainText']?.toString() ?? '',
    );
  }

  /// Copy with new values
  Proof copyWith({
    String? keysetId,
    String? amount,
    String? secret,
    String? C,
    String? witness,
    String? dleqPlainText,
  }) {
    return Proof(
      keysetId: keysetId ?? this.keysetId,
      amount: amount ?? this.amount,
      secret: secret ?? this.secret,
      C: C ?? this.C,
      witness: witness ?? this.witness,
      dleqPlainText: dleqPlainText ?? this.dleqPlainText,
    );
  }

  @override
  String toString() {
    return 'Proof(id: $id, keysetId: $keysetId, amount: $amount, secret: $secret, C: $C)';
  }
}
