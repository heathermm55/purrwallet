import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing wallet operations
class WalletService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

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
}
