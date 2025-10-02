import 'package:isar/isar.dart';
import '../../db/database_service.dart';
import '../models/proof.dart';
import '../models/history_entry.dart';
import '../../packages/rust-plugin/src/rust/api/cashu.dart';

/// Proof service for managing Cashu proofs
class ProofService {
  static final ProofService _instance = ProofService._internal();
  factory ProofService() => _instance;
  ProofService._internal();

  static ProofService get instance => _instance;

  /// Save proof to database
  Future<void> saveProof(Proof proof) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.proofs.put(proof);
    });
  }

  /// Save multiple proofs to database
  Future<void> saveProofs(List<Proof> proofs) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.proofs.putAll(proofs);
    });
  }

  /// Get all proofs
  Future<List<Proof>> getAllProofs() async {
    final isar = DatabaseService.isar;
    return await isar.proofs.where().findAll();
  }

  /// Get proofs for a specific keyset
  Future<List<Proof>> getProofsForKeyset(String keysetId) async {
    final isar = DatabaseService.isar;
    return await isar.proofs.where().keysetIdEqualTo(keysetId).findAll();
  }

  /// Get proof by secret
  Future<Proof?> getProofBySecret(String secret) async {
    final isar = DatabaseService.isar;
    return await isar.proofs.where().secretEqualTo(secret).findFirst();
  }

  /// Get total balance from proofs
  Future<int> getTotalBalance() async {
    final proofs = await getAllProofs();
    return proofs.fold(0, (sum, proof) => sum + proof.amountNum);
  }

  /// Get balance for a specific keyset
  Future<int> getBalanceForKeyset(String keysetId) async {
    final proofs = await getProofsForKeyset(keysetId);
    return proofs.fold(0, (sum, proof) => sum + proof.amountNum);
  }

  /// Delete proof
  Future<void> deleteProof(Proof proof) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.proofs.delete(proof.id);
    });
  }

  /// Delete multiple proofs
  Future<void> deleteProofs(List<Proof> proofs) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      for (final proof in proofs) {
        await isar.proofs.delete(proof.id);
      }
    });
  }

  /// Clear all proofs
  Future<void> clearAllProofs() async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.proofs.clear();
    });
  }

  /// Create proofs using CDK
  Future<List<Proof>> createProofs({
    required String mintUrl,
    required int amount,
  }) async {
    try {
      // Use CDK to create proofs
      final proofsData = await createCashuProofForMint(mintUrl, amount);
      
      // Convert to Proof objects
      final proofs = <Proof>[];
      for (final proofData in proofsData) {
        final proof = Proof.fromServerJson(proofData);
        proofs.add(proof);
      }
      
      // Save to database
      await saveProofs(proofs);
      
      return proofs;
    } catch (e) {
      throw Exception('Failed to create proofs: $e');
    }
  }

  /// Add proofs from token
  Future<List<Proof>> addProofsFromToken({
    required String token,
    required String mintUrl,
  }) async {
    try {
      // Use CDK to add proofs from token
      await addProofToWalletByToken(token);
      
      // Reload proofs from database
      return await getAllProofs();
    } catch (e) {
      throw Exception('Failed to add proofs from token: $e');
    }
  }

  /// Split proofs for exact amount
  Future<List<Proof>> splitProofs({
    required List<Proof> proofs,
    required int targetAmount,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = proofs.fold(0, (sum, proof) => sum + proof.amountNum);
      
      if (totalAmount < targetAmount) {
        throw Exception('Insufficient balance: $totalAmount < $targetAmount');
      }
      
      if (totalAmount == targetAmount) {
        return proofs;
      }
      
      // For now, return the original proofs
      // In a real implementation, this would use CDK's split functionality
      return proofs;
    } catch (e) {
      throw Exception('Failed to split proofs: $e');
    }
  }

  /// Combine proofs
  Future<List<Proof>> combineProofs({
    required List<Proof> proofs,
    required int targetAmount,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = proofs.fold(0, (sum, proof) => sum + proof.amountNum);
      
      if (totalAmount < targetAmount) {
        throw Exception('Insufficient balance: $totalAmount < $targetAmount');
      }
      
      // For now, return the original proofs
      // In a real implementation, this would use CDK's combine functionality
      return proofs;
    } catch (e) {
      throw Exception('Failed to combine proofs: $e');
    }
  }

  /// Validate proof
  bool validateProof(Proof proof) {
    try {
      // Basic validation
      if (proof.keysetId.isEmpty) return false;
      if (proof.amount.isEmpty) return false;
      if (proof.secret.isEmpty) return false;
      if (proof.C.isEmpty) return false;
      
      // Check amount is positive
      if (proof.amountNum <= 0) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get proofs summary
  Future<ProofsSummary> getProofsSummary() async {
    final proofs = await getAllProofs();
    
    final totalAmount = proofs.fold(0, (sum, proof) => sum + proof.amountNum);
    final totalCount = proofs.length;
    
    // Group by keyset
    final keysetGroups = <String, List<Proof>>{};
    for (final proof in proofs) {
      keysetGroups.putIfAbsent(proof.keysetId, () => []).add(proof);
    }
    
    final keysetBalances = <String, int>{};
    keysetGroups.forEach((keysetId, keysetProofs) {
      keysetBalances[keysetId] = keysetProofs.fold(0, (sum, proof) => sum + proof.amountNum);
    });
    
    return ProofsSummary(
      totalAmount: totalAmount,
      totalCount: totalCount,
      keysetBalances: keysetBalances,
    );
  }
}

/// Proofs summary data
class ProofsSummary {
  final int totalAmount;
  final int totalCount;
  final Map<String, int> keysetBalances;

  ProofsSummary({
    required this.totalAmount,
    required this.totalCount,
    required this.keysetBalances,
  });

  @override
  String toString() {
    return 'ProofsSummary(totalAmount: $totalAmount, totalCount: $totalCount, keysetBalances: $keysetBalances)';
  }
}
