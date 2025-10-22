import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Service for managing wallet operations
class WalletService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  // Global monitoring timer
  static Timer? _globalMonitorTimer;  // Check all wallets every 1 minute
  static bool _isGlobalMonitoring = false;  // Global monitoring status
  
  // Mint quote monitoring
  static Timer? _mintQuoteMonitorTimer;  // Check specific mint URLs every 5 seconds
  static List<String> _monitoringMintUrls = [];  // Currently monitoring mint URLs
  static bool _isMintQuoteMonitoring = false;  // Mint quote monitoring status
  
  // Melt quote monitoring
  static Timer? _meltQuoteMonitorTimer;  // Check specific melt quotes every 5 seconds
  static List<String> _monitoringMeltQuoteIds = [];  // Currently monitoring melt quote IDs
  static String? _monitoringMeltMintUrl;  // Mint URL for melt quote monitoring
  static bool _isMeltQuoteMonitoring = false;  // Melt quote monitoring status

  // Callbacks for UI updates
  static Function(Map<String, String>)? onMintedAmountReceived;
  static Function(Map<String, String>)? onMeltedAmountReceived;

  /// Initialize wallet with seed phrase
  static Future<String> initializeWallet(String seedHex) async {
    try {
      // Save seed hex to secure storage
      await _secureStorage.write(key: _seedKey, value: seedHex);

      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      // Load Tor configuration
      _loadAndApplyTorConfig();

      // Initialize MultiMintWallet
      final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);

      // Start global monitoring after wallet is initialized
      startGlobalMonitoring();

      return initResult;
    } catch (e) {
      throw Exception('Failed to initialize wallet: $e');
    }
  }

  /// Reinitialize wallet with new Tor configuration
  static Future<String> reinitializeWalletWithTorConfig() async {
    try {
      final seedHex = await getStoredSeed();
      if (seedHex == null) {
        throw Exception('No seed found in storage');
      }

      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      // Load and apply Tor configuration
      await _loadAndApplyTorConfig();

      // Reinitialize MultiMintWallet with Tor config
      final initResult = reinitializeWithTorConfig(databaseDir: databaseDir, seedHex: seedHex);

      return initResult;
    } catch (e) {
      throw Exception('Failed to reinitialize wallet with Tor config: $e');
    }
  }

  /// Load and apply Tor configuration from storage
  static Future<void> _loadAndApplyTorConfig() async {
    return;
    try {
      // Read Tor mode from SharedPreferences (same as settings page)
      final prefs = await SharedPreferences.getInstance();
      final torMode = prefs.getString('torMode') ?? 'OnionOnly';
      
      // Convert string to TorPolicy enum
      TorPolicy policy;
      switch (torMode) {
        case 'Always':
          policy = TorPolicy.always;
          break;
        case 'Never':
          policy = TorPolicy.never;
          break;
        case 'OnionOnly':
        default:
          policy = TorPolicy.onionOnly;
      }
      
      // Get application documents directory for Tor storage
      final documentsDir = await getApplicationDocumentsDirectory();
      final torCacheDir = '${documentsDir.path}/tor_cache';
      final torStateDir = '${documentsDir.path}/tor_state';
      
      // Apply Tor configuration with storage paths and bridges
      await setTorConfigWithPaths(
        policy: policy,
        cacheDir: torCacheDir,
        stateDir: torStateDir,
        bridges: null,
      );
    } catch (e) {
      // Failed to load Tor configuration
    }
  }

  /// Get stored seed hex
  static Future<String?> getStoredSeed() async {
    try {
      return await _secureStorage.read(key: _seedKey);
    } catch (e) {
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
      return false;
    }
  }

  /// Add a new mint to the wallet
  static Future<String> addMintService(String mintUrl, String unit) async {
    try {
      return await addMint(mintUrl: mintUrl);
    } catch (e) {
      String errorMsg = e.toString();
      
      // Check if this is a Tor initialization error
      if (errorMsg.contains('Tor is not initialized')) {
        // For .onion addresses, check if Tor is ready and provide helpful message
        if (mintUrl.contains('.onion')) {
          try {
            final isReady = await isTorReady();
            if (!isReady) {
              throw Exception('Tor network is still connecting. Please wait a moment and try again.\n\n⏱️ This usually takes 30-60 seconds on first connection.\n\n💡 Tip: The connection is happening in the background. Try again in a few moments.');
            }
          } catch (_) {
            // If we can't check status, provide general message
            throw Exception('Tor network is still connecting. Please wait a moment and try again.');
          }
        }
      }
      
      throw Exception('Failed to add mint: $e');
    }
  }

  /// Remove a mint from the wallet
  static Future<String> removeMintService(String mintUrl, String unit) async {
    try {
      return removeMint(mintUrl: mintUrl);
    } catch (e) {
      throw Exception('Failed to remove mint: $e');
    }
  }

  /// Get wallet info
  static Future<WalletInfo?> getWalletInfoService(String mintUrl, String unit) async {
    try {
      return await getWalletInfo(mintUrl: mintUrl);
    } catch (e) {
      String errorMsg = e.toString();
      
      // Check if this is a Tor initialization error for .onion addresses
      if (errorMsg.contains('Tor is not initialized') && mintUrl.contains('.onion')) {
        // Check if Tor is ready
        try {
          final isReady = await isTorReady();
          // Tor still connecting, mint info will be available once Tor is ready
        } catch (_) {
          // Ignore error checking status
        }
        // Return null instead of throwing, so UI can handle gracefully
        return null;
      }
      return null;
    }
  }

  /// Get wallet balance for a specific mint URL
  static Future<BigInt> getWalletBalanceService(String mintUrl, String unit) async {
    try {
      final allBalances = await getAllBalances();
      final key = '$mintUrl:$unit';
      final balance = allBalances[key] ?? 0;
      return BigInt.from(balance as int);
    } catch (e) {
      return BigInt.zero;
    }
  }

  /// Get wallet transactions for a specific mint URL
  static Future<List<TransactionInfo>> getWalletTransactionsService(String mintUrl, String unit) async {
    try {
      final allTransactions = await getAllTransactions();
      // Filter transactions for the specific mint URL
      return allTransactions.where((tx) {
        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear wallet data (for logout)
  static Future<void> clearWalletData() async {
    try {
      await _secureStorage.delete(key: _seedKey);
    } catch (e) {
      // Failed to clear wallet data
    }
  }

  // ==================== Monitoring Methods ====================

  /// Start global monitoring (check all wallets every 1 minute)
  static void startGlobalMonitoring() {
    if (_isGlobalMonitoring) {
      return;
    }

    _isGlobalMonitoring = true;

    _globalMonitorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAllMintQuotes();
      _checkAllMeltQuotes();
    });

    // Start immediate check
    _checkAllMintQuotes();
    _checkAllMeltQuotes();
  }

  /// Stop global monitoring
  static void stopGlobalMonitoring() {
    if (!_isGlobalMonitoring) {
      return;
    }

    _isGlobalMonitoring = false;
    _globalMonitorTimer?.cancel();
    _globalMonitorTimer = null;
  }

  /// Start mint quote monitoring for specific mint URLs (check every 5 seconds for 5 minutes)
  static void startMintQuoteMonitoring(List<String> mintUrls) {
    // Stop any existing mint quote monitoring first
    stopMintQuoteMonitoring();

    _monitoringMintUrls = List.from(mintUrls);
    _isMintQuoteMonitoring = true;

    int checkCount = 0;
    const maxChecks = 60; // 5 minutes = 60 * 5 seconds

    _mintQuoteMonitorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkCount++;
      
      // Check specific mint URLs
      _checkSpecificMintQuotes(mintUrls);

      if (checkCount >= maxChecks) {
        stopMintQuoteMonitoring();
      }
    });

    // Start immediate check
    _checkSpecificMintQuotes(mintUrls);
  }

  /// Start melt quote monitoring for specific quote IDs (check every 5 seconds for 3 minutes)
  static void startMeltQuoteMonitoring(List<String> meltQuoteIds, String mintUrl) {
    // Stop any existing melt quote monitoring first
    stopMeltQuoteMonitoring();

    _monitoringMeltQuoteIds = List.from(meltQuoteIds);
    _monitoringMeltMintUrl = mintUrl;
    _isMeltQuoteMonitoring = true;

    int checkCount = 0;
    const maxChecks = 60; // 5 minutes = 60 * 5 seconds

    _meltQuoteMonitorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkCount++;
      
      // Check specific melt quotes
      _checkSpecificMeltQuotes(meltQuoteIds, mintUrl);

      if (checkCount >= maxChecks) {
        stopMeltQuoteMonitoring();
      }
    });

    // Start immediate check
    _checkSpecificMeltQuotes(meltQuoteIds, mintUrl);
  }

  /// Stop mint quote monitoring
  static void stopMintQuoteMonitoring() {
    _isMintQuoteMonitoring = false;
    _mintQuoteMonitorTimer?.cancel();
    _mintQuoteMonitorTimer = null;
    _monitoringMintUrls.clear();
  }

  /// Stop melt quote monitoring
  static void stopMeltQuoteMonitoring() {
    _isMeltQuoteMonitoring = false;
    _meltQuoteMonitorTimer?.cancel();
    _meltQuoteMonitorTimer = null;
    _monitoringMeltQuoteIds.clear();
    _monitoringMeltMintUrl = null;
  }

  /// Check all melt quotes across all wallets
  static Future<void> _checkAllMeltQuotes() async {
    try {
      // Check all melt quotes across all wallets
      final result = await checkAllMeltQuotes();
      final totalCompleted = int.parse(result);

      if (totalCompleted > 0) {
        // Notify UI about completed melt quotes
        if (onMeltedAmountReceived != null) {
          onMeltedAmountReceived!({
            'completed_count': totalCompleted.toString(),
            'source': 'global_monitoring',
          });
        }
      }

    } catch (e) {
      // Silently ignore JSON parsing errors (quote not paid yet or expired)
    }
  }

  /// Check all mint quotes across all wallets
  static Future<void> _checkAllMintQuotes() async {
    try {
      // Use the new checkAllMintQuotes API
      final result = await checkAllMintQuotes();
      final totalMinted = int.parse(result['total_minted'] ?? '0');

      if (totalMinted > 0) {
        // Notify UI about minted amount
        if (onMintedAmountReceived != null) {
          onMintedAmountReceived!(result);
        }
      }

    } catch (e) {
      // Silently ignore JSON parsing errors (quote not paid yet or expired)
      if (!e.toString().contains('expected value at line 1 column 1')) {
      }
    }
  }

  /// Check specific mint quotes for given mint URLs
  static Future<void> _checkSpecificMintQuotes(List<String> mintUrls) async {
    try {
      
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
          }
        } catch (e) {
          // Silently ignore JSON parsing errors (quote not paid yet or expired)
          if (!e.toString().contains('expected value at line 1 column 1')) {
          }
        }
      }

      if (totalMinted > 0) {
        
        // Notify UI about minted amount
        if (onMintedAmountReceived != null) {
          onMintedAmountReceived!({
            'total_minted': totalMinted.toString(),
            'source': 'specific_monitoring',
          });
        }
      } else {
      }

    } catch (e) {
      // Silently ignore JSON parsing errors (quote not paid yet or expired)
      if (!e.toString().contains('expected value at line 1 column 1')) {
      }
    }
  }

  /// Check specific melt quotes for given quote IDs
  static Future<void> _checkSpecificMeltQuotes(List<String> meltQuoteIds, String mintUrl) async {
    try {
      
      // Check all melt quotes for this mint URL
      final result = await checkMeltQuoteStatus(mintUrl: mintUrl);
      final completedCount = int.parse(result);
      
      if (completedCount > 0) {
        
        // Notify UI about completed melt quotes
        if (onMeltedAmountReceived != null) {
          onMeltedAmountReceived!({
            'completed_count': completedCount.toString(),
            'source': 'specific_monitoring',
            'mint_url': mintUrl,
          });
        }
      } else {
      }

    } catch (e) {
      // Silently ignore JSON parsing errors (quote not paid yet or expired)
      if (!e.toString().contains('expected value at line 1 column 1')) {
      }
    }
  }

  /// Get monitoring status
  static Map<String, dynamic> getMonitoringStatus() {
    return {
      'globalMonitoring': _isGlobalMonitoring,
      'mintQuoteMonitoring': _isMintQuoteMonitoring,
      'meltQuoteMonitoring': _isMeltQuoteMonitoring,
      'monitoringMintUrls': List.from(_monitoringMintUrls),
      'monitoringMeltQuoteIds': List.from(_monitoringMeltQuoteIds),
      'monitoringMeltMintUrl': _monitoringMeltMintUrl,
      'globalTimerActive': _globalMonitorTimer?.isActive ?? false,
      'mintQuoteTimerActive': _mintQuoteMonitorTimer?.isActive ?? false,
      'meltQuoteTimerActive': _meltQuoteMonitorTimer?.isActive ?? false,
    };
  }

  /// Stop all monitoring
  static void stopAllMonitoring() {
    stopGlobalMonitoring();
    stopMintQuoteMonitoring();
    stopMeltQuoteMonitoring();
  }
}
