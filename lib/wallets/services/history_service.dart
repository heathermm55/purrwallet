import 'package:isar/isar.dart';
import '../../db/database_service.dart';
import '../models/history_entry.dart';

/// History service for managing transaction history
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static HistoryService get instance => _instance;

  /// Save history entry
  Future<void> saveHistoryEntry(HistoryEntry entry) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.historyEntries.put(entry);
    });
  }

  /// Save multiple history entries
  Future<void> saveHistoryEntries(List<HistoryEntry> entries) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.historyEntries.putAll(entries);
    });
  }

  /// Get all history entries (sorted by timestamp desc)
  Future<List<HistoryEntry>> getAllHistory() async {
    final isar = DatabaseService.isar;
    return await isar.historyEntries.where().sortByTimestampDesc().findAll();
  }

  /// Get history entries for a specific mint
  Future<List<HistoryEntry>> getHistoryForMint(String mintUrl) async {
    final isar = DatabaseService.isar;
    return await isar.historyEntries.where().sortByTimestampDesc().findAll();
  }

  /// Get history entries by type
  Future<List<HistoryEntry>> getHistoryByType(HistoryType type) async {
    final isar = DatabaseService.isar;
    return await isar.historyEntries.where().sortByTimestampDesc().findAll();
  }

  /// Get recent history entries
  Future<List<HistoryEntry>> getRecentHistory({int limit = 50}) async {
    final isar = DatabaseService.isar;
    return await isar.historyEntries.where().sortByTimestampDesc().limit(limit).findAll();
  }

  /// Get history entries in date range
  Future<List<HistoryEntry>> getHistoryInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final isar = DatabaseService.isar;
    final startTimestamp = start.millisecondsSinceEpoch / 1000.0;
    final endTimestamp = end.millisecondsSinceEpoch / 1000.0;
    
    return await isar.historyEntries
        .where()
        .timestampBetween(startTimestamp, endTimestamp)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Delete history entry
  Future<void> deleteHistoryEntry(HistoryEntry entry) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.historyEntries.delete(entry.id);
    });
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.historyEntries.clear();
    });
  }

  /// Add eCash transaction to history
  Future<HistoryEntry> addECashTransaction({
    required double amount,
    required String token,
    required List<String> mints,
    String memo = '',
    bool isSpent = false,
  }) async {
    final entry = HistoryEntry.fromTransaction(
      amount: amount,
      type: HistoryType.eCash,
      value: token,
      mints: mints,
      memo: memo,
      isSpent: isSpent,
    );
    
    await saveHistoryEntry(entry);
    return entry;
  }

  /// Add Lightning invoice transaction to history
  Future<HistoryEntry> addLightningTransaction({
    required double amount,
    required String paymentRequest,
    required List<String> mints,
    String memo = '',
  }) async {
    final entry = HistoryEntry.fromTransaction(
      amount: amount,
      type: HistoryType.lnInvoice,
      value: paymentRequest,
      mints: mints,
      memo: memo,
    );
    
    await saveHistoryEntry(entry);
    return entry;
  }

  /// Add multi-mint swap transaction to history
  Future<HistoryEntry> addMultiMintSwapTransaction({
    required double amount,
    required String swapData,
    required List<String> mints,
    String memo = '',
  }) async {
    final entry = HistoryEntry.fromTransaction(
      amount: amount,
      type: HistoryType.multiMintSwap,
      value: swapData,
      mints: mints,
      memo: memo,
    );
    
    await saveHistoryEntry(entry);
    return entry;
  }

  /// Get transaction statistics
  Future<TransactionStats> getTransactionStats() async {
    final entries = await getAllHistory();
    
    int totalTransactions = entries.length;
    double totalAmount = 0;
    int eCashCount = 0;
    int lightningCount = 0;
    int swapCount = 0;
    
    final mintStats = <String, MintStats>{};
    
    for (final entry in entries) {
      totalAmount += entry.amount;
      
      switch (entry.type) {
        case HistoryType.eCash:
          eCashCount++;
          break;
        case HistoryType.lnInvoice:
          lightningCount++;
          break;
        case HistoryType.multiMintSwap:
          swapCount++;
          break;
        default:
          break;
      }
      
      // Update mint statistics
      for (final mint in entry.mints) {
        mintStats.putIfAbsent(mint, () => MintStats(mint));
        mintStats[mint]!.addTransaction(entry);
      }
    }
    
    return TransactionStats(
      totalTransactions: totalTransactions,
      totalAmount: totalAmount,
      eCashCount: eCashCount,
      lightningCount: lightningCount,
      swapCount: swapCount,
      mintStats: mintStats.values.toList(),
    );
  }

  /// Search history entries
  Future<List<HistoryEntry>> searchHistory(String query) async {
    final entries = await getAllHistory();
    
    if (query.isEmpty) return entries;
    
    final lowercaseQuery = query.toLowerCase();
    return entries.where((entry) {
      return entry.memo.toLowerCase().contains(lowercaseQuery) ||
             entry.value.toLowerCase().contains(lowercaseQuery) ||
             entry.mints.any((mint) => mint.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Export history to JSON
  Future<Map<String, dynamic>> exportHistory() async {
    final entries = await getAllHistory();
    
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'total_entries': entries.length,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }
}

/// Transaction statistics
class TransactionStats {
  final int totalTransactions;
  final double totalAmount;
  final int eCashCount;
  final int lightningCount;
  final int swapCount;
  final List<MintStats> mintStats;

  TransactionStats({
    required this.totalTransactions,
    required this.totalAmount,
    required this.eCashCount,
    required this.lightningCount,
    required this.swapCount,
    required this.mintStats,
  });

  @override
  String toString() {
    return 'TransactionStats(totalTransactions: $totalTransactions, totalAmount: $totalAmount, eCashCount: $eCashCount, lightningCount: $lightningCount, swapCount: $swapCount)';
  }
}

/// Mint statistics
class MintStats {
  final String mintUrl;
  int transactionCount = 0;
  double totalAmount = 0;
  int eCashCount = 0;
  int lightningCount = 0;

  MintStats(this.mintUrl);

  void addTransaction(HistoryEntry entry) {
    transactionCount++;
    totalAmount += entry.amount;
    
    switch (entry.type) {
      case HistoryType.eCash:
        eCashCount++;
        break;
      case HistoryType.lnInvoice:
        lightningCount++;
        break;
      default:
        break;
    }
  }

  @override
  String toString() {
    return 'MintStats(mintUrl: $mintUrl, transactionCount: $transactionCount, totalAmount: $totalAmount)';
  }
}
