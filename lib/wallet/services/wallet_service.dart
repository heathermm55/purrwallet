import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      await _loadAndApplyTorConfig();

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
      print('MultiMintWallet reinit with Tor result: $initResult');

      return initResult;
    } catch (e) {
      throw Exception('Failed to reinitialize wallet with Tor config: $e');
    }
  }

  /// Load and apply Tor configuration from storage
  static Future<void> _loadAndApplyTorConfig() async {
    try {
      final torEnabled = await _secureStorage.read(key: 'tor_enabled');
      final torMode = await _secureStorage.read(key: 'tor_mode');
      
      if (torEnabled == 'true' && torMode != null) {
        // Convert string to TorPolicy enum
        TorPolicy policy;
        switch (torMode) {
          case 'OnionOnly':
            policy = TorPolicy.onionOnly;
            break;
          case 'Always':
            policy = TorPolicy.always;
            break;
          default:
            policy = TorPolicy.onionOnly;
        }
        
        // Apply Tor configuration
        await setTorConfig(policy: policy);
        print('Applied Tor configuration: $torMode');
      }
    } catch (e) {
      print('Failed to load Tor configuration: $e');
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
      return addMint(mintUrl: mintUrl);
    } catch (e) {
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
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      return getWalletInfo(mintUrl: mintUrl);
    } catch (e) {
      print('Failed to get wallet info: $e');
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
      print('Failed to get wallet balance: $e');
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
    print('Global monitoring stopped');
  }

  /// Start mint quote monitoring for specific mint URLs (check every 5 seconds for 5 minutes)
  static void startMintQuoteMonitoring(List<String> mintUrls) {
    // Stop any existing mint quote monitoring first
    stopMintQuoteMonitoring();

    _monitoringMintUrls = List.from(mintUrls);
    _isMintQuoteMonitoring = true;
    print('Starting mint quote monitoring for ${mintUrls.length} mints (every 5 seconds for 5 minutes)');

    int checkCount = 0;
    const maxChecks = 60; // 5 minutes = 60 * 5 seconds

    _mintQuoteMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    print('Starting melt quote monitoring for ${meltQuoteIds.length} quotes (every 5 seconds for 3 minutes)');

    int checkCount = 0;
    const maxChecks = 60; // 5 minutes = 60 * 5 seconds

    _meltQuoteMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    print('Mint quote monitoring stopped');
  }

  /// Stop melt quote monitoring
  static void stopMeltQuoteMonitoring() {
    _isMeltQuoteMonitoring = false;
    _meltQuoteMonitorTimer?.cancel();
    _meltQuoteMonitorTimer = null;
    _monitoringMeltQuoteIds.clear();
    _monitoringMeltMintUrl = null;
    print('Melt quote monitoring stopped');
  }

  /// Check all melt quotes across all wallets
  static Future<void> _checkAllMeltQuotes() async {
    try {
      print('Checking all melt quotes...');
      
      // Check all melt quotes across all wallets
      final result = await checkAllMeltQuotes();
      final totalCompleted = int.parse(result);

      if (totalCompleted > 0) {
        print('Global monitoring: Total $totalCompleted melt quotes completed');
        
        // Notify UI about completed melt quotes
        if (onMeltedAmountReceived != null) {
          onMeltedAmountReceived!({
            'completed_count': totalCompleted.toString(),
            'source': 'global_monitoring',
          });
        }
      } else {
        print('Global monitoring: No melt quotes completed');
      }

    } catch (e) {
      print('Error in global melt monitoring: $e');
    }
  }

  /// Check all mint quotes across all wallets
  static Future<void> _checkAllMintQuotes() async {
    try {
      print('Checking all mint quotes...');
      
      // Use the new checkAllMintQuotes API
      final result = await checkAllMintQuotes();
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

  /// Check specific melt quotes for given quote IDs
  static Future<void> _checkSpecificMeltQuotes(List<String> meltQuoteIds, String mintUrl) async {
    try {
      print('Checking specific melt quotes for ${meltQuoteIds.length} quotes...');
      
      // Check all melt quotes for this mint URL
      final result = await checkMeltQuoteStatus(mintUrl: mintUrl);
      final completedCount = int.parse(result);
      
      if (completedCount > 0) {
        print('Specific monitoring: $completedCount melt quotes completed for $mintUrl');
        
        // Notify UI about completed melt quotes
        if (onMeltedAmountReceived != null) {
          onMeltedAmountReceived!({
            'completed_count': completedCount.toString(),
            'source': 'specific_monitoring',
            'mint_url': mintUrl,
          });
        }
      } else {
        print('Specific monitoring: No melt quotes completed for $mintUrl');
      }

    } catch (e) {
      print('Error in specific melt monitoring: $e');
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
