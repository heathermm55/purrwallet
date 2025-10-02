import 'package:isar/isar.dart';

part 'invoice.g.dart';

/// Invoice state enum
enum InvoiceState {
  pending(0),
  paid(1),
  expired(2),
  cancelled(3);

  const InvoiceState(this.value);
  final int value;

  static InvoiceState fromValue(dynamic value) =>
      InvoiceState.values.where((element) => element.value == value).firstOrNull ?? InvoiceState.pending;
}

/// Lightning invoice model for Isar database
@collection
class Invoice {
  Invoice({
    required this.paymentHash,
    required this.paymentRequest,
    required this.amount,
    required this.mintURL,
    required this.stateRaw,
    required this.createdAt,
    this.paidAt,
    this.expiresAt,
    this.description = '',
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String paymentHash;

  late String paymentRequest;
  late double amount;
  late String mintURL;
  late int stateRaw;
  late int createdAt;
  int? paidAt;
  int? expiresAt;
  late String description;

  /// Get invoice state enum
  @ignore
  InvoiceState get state => InvoiceState.fromValue(stateRaw);

  /// Create from Lightning invoice data
  factory Invoice.fromLightningInvoice({
    required String paymentHash,
    required String paymentRequest,
    required double amount,
    required String mintURL,
    String description = '',
    int? expiresAt,
  }) {
    return Invoice(
      paymentHash: paymentHash,
      paymentRequest: paymentRequest,
      amount: amount,
      mintURL: mintURL,
      stateRaw: InvoiceState.pending.value,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: expiresAt,
      description: description,
    );
  }

  /// Mark as paid
  void markAsPaid() {
    stateRaw = InvoiceState.paid.value;
    paidAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Mark as expired
  void markAsExpired() {
    stateRaw = InvoiceState.expired.value;
  }

  /// Mark as cancelled
  void markAsCancelled() {
    stateRaw = InvoiceState.cancelled.value;
  }

  /// Check if invoice is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt!;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'paymentHash': paymentHash,
    'paymentRequest': paymentRequest,
    'amount': amount,
    'mintURL': mintURL,
    'state': stateRaw,
    'createdAt': createdAt,
    if (paidAt != null) 'paidAt': paidAt,
    if (expiresAt != null) 'expiresAt': expiresAt,
    'description': description,
  };

  @override
  String toString() {
    return 'Invoice(id: $id, paymentHash: $paymentHash, amount: $amount, state: $state)';
  }
}
