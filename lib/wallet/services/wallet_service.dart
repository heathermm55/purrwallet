import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

/// Service for managing wallet operations
class WalletService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  // Monitoring timers
  static Timer? _globalMonitorTimer;  // Check all wallets every 1 minute
  static Timer? _specificMonitorTimer;  // Check specific wallets every 5 seconds
  static List<String> _monitoringMintUrls = [];  // Currently monitoring mint URLs
  static bool _isGlobalMonitoring = false;  // Global monitoring status
  static bool _isSpecificMonitoring = false;  // Specific monitoring status

  // Callbacks for UI updates
  static Function(Map<String, String>)? onMintedAmountReceived;

  /// Initialize wallet with seed phrase
  static Future<String> initializeWallet(String seedHex) async {
    try {
      // Save seed hex to secure storage
      await _secureStorage.write(key: _seedKey, value: seedHex);

      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      // Initialize MultiMintWallet
      final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);
      print('MultiMintWallet init result: $initResult');

      // Start global monitoring after wallet is initialized
      startGlobalMonitoring();

      return initResult;
    } catch (e) {
      throw Exception('Failed to initialize wallet: $e');
    }
  }

  /// Get stored seed hex
  static Future<String?> getStoredSeed() async {
    try {
      return await _secureStorage.read(key: _seedKey);
    } catch (e) {
      print('Failed to read stored seed: $e');
      return null;
    }
  }

  /// Check if wallet exists
  static Future<bool> checkWalletExists(String mintUrl) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      return walletExists(mintUrl: mintUrl, databaseDir: databaseDir);
    } catch (e) {
      print('Failed to check wallet existence: $e');
      return false;
    }
  }

  /// Add a new mint to the wallet
  static Future<String> addMintService(String mintUrl, String unit) async {
    try {
      return addMint(mintUrl: mintUrl, unit: unit);
    } catch (e) {
      throw Exception('Failed to add mint: $e');
    }
  }

  /// Remove a mint from the wallet
  static Future<String> removeMintService(String mintUrl, String unit) async {
    try {
      return removeMint(mintUrl: mintUrl, unit: unit);
    } catch (e) {
      throw Exception('Failed to remove mint: $e');
    }
  }

  /// Get wallet info
  static Future<WalletInfo?> getWalletInfoService(String mintUrl, String unit) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      return getWalletInfo(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
    } catch (e) {
      print('Failed to get wallet info: $e');
      return null;
    }
  }

  /// Get wallet balance
  static Future<BigInt> getWalletBalanceService(String mintUrl, String unit) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      final balance = getWalletBalance(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
      return balance;
    } catch (e) {
      print('Failed to get wallet balance: $e');
      return BigInt.zero;
    }
  }

  /// Get wallet transactions
  static Future<List<TransactionInfo>> getWalletTransactionsService(String mintUrl, String unit) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      return getWalletTransactions(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
    } catch (e) {
      print('Failed to get wallet transactions: $e');
      return [];
    }
  }

  /// Clear wallet data (for logout)
  static Future<void> clearWalletData() async {
    try {
      await _secureStorage.delete(key: _seedKey);
    } catch (e) {
      print('Failed to clear wallet data: $e');
    }
  }

  // ==================== Monitoring Methods ====================

  /// Start global monitoring (check all wallets every 1 minute)
  static void startGlobalMonitoring() {
    if (_isGlobalMonitoring) {
      print('Global monitoring already running');
      return;
    }

    _isGlobalMonitoring = true;
    print('Starting global monitoring (every 1 minute)');

    _globalMonitorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAllMintQuotes();
    });

    // Start immediate check
    _checkAllMintQuotes();
  }

  /// Stop global monitoring
  static void stopGlobalMonitoring() {
    if (!_isGlobalMonitoring) {
      return;
    }

    _isGlobalMonitoring = false;
    _globalMonitorTimer?.cancel();
    _globalMonitorTimer = null;
    print('Global monitoring stopped');
  }

  /// Start specific monitoring for mint URLs (check every 5 seconds for 5 minutes)
  static void startSpecificMonitoring(List<String> mintUrls) {
    // Stop any existing specific monitoring first
    stopSpecificMonitoring();

    _monitoringMintUrls = List.from(mintUrls);
    _isSpecificMonitoring = true;
    print('Starting specific monitoring for ${mintUrls.length} mints (every 5 seconds for 5 minutes)');

    int checkCount = 0;
    const maxChecks = 60; // 5 minutes = 60 * 5 seconds

    _specificMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkCount++;
      
      // Check specific mint URLs
      _checkSpecificMintQuotes(mintUrls);

      if (checkCount >= maxChecks) {
        stopSpecificMonitoring();
      }
    });

    // Start immediate check
    _checkSpecificMintQuotes(mintUrls);
  }

  /// Stop specific monitoring
  static void stopSpecificMonitoring() {
    _isSpecificMonitoring = false;
    _specificMonitorTimer?.cancel();
    _specificMonitorTimer = null;
    _monitoringMintUrls.clear();
    print('Specific monitoring stopped');
  }

  /// Check all mint quotes across all wallets
  static Future<void> _checkAllMintQuotes() async {
    try {
      print('Checking all mint quotes...');
      
      // Use the new API to check all pending mint quotes
      final result = await checkAllPendingMintQuotes();
      final totalMinted = int.parse(result['total_minted'] ?? '0');

      if (totalMinted > 0) {
        print('Global monitoring: Successfully minted $totalMinted sats');
        
        // Notify UI about minted amount
        if (onMintedAmountReceived != null) {
          onMintedAmountReceived!(result);
        }
      } else {
        print('Global monitoring: No payments received');
      }

    } catch (e) {
      print('Error in global monitoring: $e');
    }
  }

  /// Check specific mint quotes for given mint URLs
  static Future<void> _checkSpecificMintQuotes(List<String> mintUrls) async {
    try {
      print('Checking specific mint quotes for ${mintUrls.length} mints...');
      
      int totalMinted = 0;
      
      for (final mintUrl in mintUrls) {
        try {
          // Check mint quote status for this specific mint
          final result = await checkMintQuoteStatus(
            mintUrl: mintUrl,
          );
          
          final mintedAmount = int.parse(result);
          if (mintedAmount > 0) {
            totalMinted += mintedAmount;
            print('Specific monitoring: Minted $mintedAmount sats from $mintUrl');
          }
        } catch (e) {
          print('Error checking mint $mintUrl: $e');
        }
      }

      if (totalMinted > 0) {
        print('Specific monitoring: Total minted $totalMinted sats');
        
        // Notify UI about minted amount
        if (onMintedAmountReceived != null) {
          onMintedAmountReceived!({
            'total_minted': totalMinted.toString(),
            'source': 'specific_monitoring',
          });
        }
      } else {
        print('Specific monitoring: No payments received');
      }

    } catch (e) {
      print('Error in specific monitoring: $e');
    }
  }

  /// Get monitoring status
  static Map<String, dynamic> getMonitoringStatus() {
    return {
      'globalMonitoring': _isGlobalMonitoring,
      'specificMonitoring': _isSpecificMonitoring,
      'monitoringMintUrls': List.from(_monitoringMintUrls),
      'globalTimerActive': _globalMonitorTimer?.isActive ?? false,
      'specificTimerActive': _specificMonitorTimer?.isActive ?? false,
    };
  }

  /// Stop all monitoring
  static void stopAllMonitoring() {
    stopGlobalMonitoring();
    stopSpecificMonitoring();
  }
}
