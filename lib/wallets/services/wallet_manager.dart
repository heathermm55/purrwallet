import 'dart:async';
import 'package:isar/isar.dart';
import '../../db/database_service.dart';
import '../models/proof.dart';
import '../models/mint_info.dart';
import '../models/keyset_info.dart';
import '../models/history_entry.dart';
import '../models/invoice.dart';
import '../../packages/rust-plugin/src/rust/api/cashu.dart';

/// Wallet manager service for managing Cashu wallets
class WalletManager {
  static final WalletManager _instance = WalletManager._internal();
  factory WalletManager() => _instance;
  WalletManager._internal();

  static WalletManager get instance => _instance;

  // Wallet state
  String? _currentUserPubkey;
  final List<MintInfo> _mints = [];
  final List<Proof> _proofs = [];
  final List<HistoryEntry> _history = [];
  final List<Invoice> _invoices = [];

  // Listeners for wallet events
  final List<WalletListener> _listeners = [];

  /// Current user's public key
  String? get currentUserPubkey => _currentUserPubkey;

  /// Get all mints
  List<MintInfo> get mints => List.unmodifiable(_mints);

  /// Get all proofs
  List<Proof> get proofs => List.unmodifiable(_proofs);

  /// Get all history entries
  List<HistoryEntry> get history => List.unmodifiable(_history);

  /// Get all invoices
  List<Invoice> get invoices => List.unmodifiable(_invoices);

  /// Initialize wallet for a user
  Future<void> initializeWallet(String userPubkey) async {
    _currentUserPubkey = userPubkey;
    
    // Open user's database
    await DatabaseService.openUserDatabase(userPubkey);
    
    // Load wallet data
    await _loadWalletData();
    
    // Initialize CDK wallet manager
    await _initializeCdkWallet();
    
    _notifyListeners(WalletEvent.initialized);
  }

  /// Load wallet data from database
  Future<void> _loadWalletData() async {
    if (_currentUserPubkey == null) return;

    final isar = DatabaseService.isar;
    
    // Load mints
    _mints.clear();
    _mints.addAll(await isar.mintInfos.where().findAll());
    
    // Load proofs
    _proofs.clear();
    _proofs.addAll(await isar.proofs.where().findAll());
    
    // Load history
    _history.clear();
    _history.addAll(await isar.historyEntries.where().sortByTimestampDesc().findAll());
    
    // Load invoices
    _invoices.clear();
    _invoices.addAll(await isar.invoices.where().findAll());
  }

  /// Initialize CDK wallet manager
  Future<void> _initializeCdkWallet() async {
    try {
      // Create wallet manager using CDK
      await createWalletManager();
      _notifyListeners(WalletEvent.cdkInitialized);
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to initialize CDK wallet: $e'));
    }
  }

  /// Add a new mint
  Future<void> addMint(String mintUrl) async {
    if (_currentUserPubkey == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      // Add mint to CDK
      await addCashuMint(mintUrl);
      
      // Fetch mint info
      final mintInfo = await _fetchMintInfo(mintUrl);
      
      // Save to database
      final isar = DatabaseService.isar;
      await isar.writeTxn(() async {
        await isar.mintInfos.put(mintInfo);
      });
      
      // Update local state
      _mints.add(mintInfo);
      
      _notifyListeners(WalletEvent.mintAdded(mintInfo));
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to add mint: $e'));
      rethrow;
    }
  }

  /// Fetch mint information from server
  Future<MintInfo> _fetchMintInfo(String mintUrl) async {
    // This would typically make an HTTP request to the mint
    // For now, we'll create a placeholder
    return MintInfo.fromServerMap({
      'name': 'Mint',
      'pubkey': 'placeholder',
      'version': '0.1.0',
      'description': 'Cashu Mint',
      'description_long': 'A Cashu mint server',
      'contact': [],
      'motd': 'Welcome to Cashu!',
      'nuts': {},
    }, mintUrl);
  }

  /// Get wallet balance for a specific mint
  Future<int> getBalance(String mintUrl) async {
    try {
      return await getWalletBalance(mintUrl);
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to get balance: $e'));
      return 0;
    }
  }

  /// Get total balance across all mints
  Future<int> getTotalBalance() async {
    int total = 0;
    for (final mint in _mints) {
      total += await getBalance(mint.mintURL);
    }
    return total;
  }

  /// Send tokens
  Future<String> sendTokens({
    required String mintUrl,
    required int amount,
    required String memo,
  }) async {
    if (_currentUserPubkey == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      // Create proofs using CDK
      final proofs = await createCashuProofForMint(mintUrl, amount);
      
      // Save proofs to database
      final isar = DatabaseService.isar;
      await isar.writeTxn(() async {
        for (final proofData in proofs) {
          final proof = Proof.fromServerJson(proofData);
          await isar.proofs.put(proof);
        }
      });
      
      // Update local state
      await _loadWalletData();
      
      // Add to history
      final historyEntry = HistoryEntry.fromTransaction(
        amount: amount.toDouble(),
        type: HistoryType.eCash,
        value: memo,
        mints: [mintUrl],
        memo: memo,
      );
      
      await isar.writeTxn(() async {
        await isar.historyEntries.put(historyEntry);
      });
      
      _history.insert(0, historyEntry);
      
      _notifyListeners(WalletEvent.tokensSent(amount, mintUrl));
      
      return memo; // Return memo as token identifier
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to send tokens: $e'));
      rethrow;
    }
  }

  /// Receive tokens
  Future<void> receiveTokens({
    required String token,
    required String mintUrl,
  }) async {
    if (_currentUserPubkey == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      // Parse and add token using CDK
      await addProofToWalletByToken(token);
      
      // Reload wallet data
      await _loadWalletData();
      
      _notifyListeners(WalletEvent.tokensReceived(token, mintUrl));
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to receive tokens: $e'));
      rethrow;
    }
  }

  /// Create Lightning invoice
  Future<Invoice> createInvoice({
    required String mintUrl,
    required int amount,
    String description = '',
  }) async {
    if (_currentUserPubkey == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      // Create invoice using CDK
      final invoiceData = await createCashuInvoice(mintUrl, amount);
      
      // Create invoice object
      final invoice = Invoice.fromLightningInvoice(
        paymentHash: invoiceData['payment_hash'] ?? '',
        paymentRequest: invoiceData['payment_request'] ?? '',
        amount: amount.toDouble(),
        mintURL: mintUrl,
        description: description,
        expiresAt: invoiceData['expires_at'],
      );
      
      // Save to database
      final isar = DatabaseService.isar;
      await isar.writeTxn(() async {
        await isar.invoices.put(invoice);
      });
      
      _invoices.add(invoice);
      
      _notifyListeners(WalletEvent.invoiceCreated(invoice));
      
      return invoice;
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to create invoice: $e'));
      rethrow;
    }
  }

  /// Pay Lightning invoice
  Future<void> payInvoice({
    required String paymentRequest,
    required String mintUrl,
  }) async {
    if (_currentUserPubkey == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      // Pay invoice using CDK
      await payCashuInvoice(paymentRequest, mintUrl);
      
      // Find and update invoice
      final invoice = _invoices.firstWhere(
        (inv) => inv.paymentRequest == paymentRequest,
        orElse: () => throw Exception('Invoice not found'),
      );
      
      invoice.markAsPaid();
      
      // Update database
      final isar = DatabaseService.isar;
      await isar.writeTxn(() async {
        await isar.invoices.put(invoice);
      });
      
      // Add to history
      final historyEntry = HistoryEntry.fromTransaction(
        amount: invoice.amount,
        type: HistoryType.lnInvoice,
        value: paymentRequest,
        mints: [mintUrl],
        memo: invoice.description,
      );
      
      await isar.writeTxn(() async {
        await isar.historyEntries.put(historyEntry);
      });
      
      _history.insert(0, historyEntry);
      
      _notifyListeners(WalletEvent.invoicePaid(invoice));
    } catch (e) {
      _notifyListeners(WalletEvent.error('Failed to pay invoice: $e'));
      rethrow;
    }
  }

  /// Add wallet listener
  void addListener(WalletListener listener) {
    _listeners.add(listener);
  }

  /// Remove wallet listener
  void removeListener(WalletListener listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners(WalletEvent event) {
    for (final listener in _listeners) {
      listener.onWalletEvent(event);
    }
  }

  /// Clear wallet data
  Future<void> clearWallet() async {
    _currentUserPubkey = null;
    _mints.clear();
    _proofs.clear();
    _history.clear();
    _invoices.clear();
    _listeners.clear();
  }
}

/// Wallet event types
enum WalletEventType {
  initialized,
  cdkInitialized,
  mintAdded,
  tokensSent,
  tokensReceived,
  invoiceCreated,
  invoicePaid,
  error,
}

/// Wallet event
class WalletEvent {
  final WalletEventType type;
  final dynamic data;

  WalletEvent(this.type, this.data);

  factory WalletEvent.initialized() => WalletEvent(WalletEventType.initialized, null);
  factory WalletEvent.cdkInitialized() => WalletEvent(WalletEventType.cdkInitialized, null);
  factory WalletEvent.mintAdded(MintInfo mint) => WalletEvent(WalletEventType.mintAdded, mint);
  factory WalletEvent.tokensSent(int amount, String mintUrl) => 
      WalletEvent(WalletEventType.tokensSent, {'amount': amount, 'mintUrl': mintUrl});
  factory WalletEvent.tokensReceived(String token, String mintUrl) => 
      WalletEvent(WalletEventType.tokensReceived, {'token': token, 'mintUrl': mintUrl});
  factory WalletEvent.invoiceCreated(Invoice invoice) => 
      WalletEvent(WalletEventType.invoiceCreated, invoice);
  factory WalletEvent.invoicePaid(Invoice invoice) => 
      WalletEvent(WalletEventType.invoicePaid, invoice);
  factory WalletEvent.error(String message) => WalletEvent(WalletEventType.error, message);
}

/// Wallet listener interface
abstract class WalletListener {
  void onWalletEvent(WalletEvent event);
}
