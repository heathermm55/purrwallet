import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../../db/database_service.dart';
import '../models/mint_info.dart';
import '../models/keyset_info.dart';

/// Mint service for managing Cashu mints
class MintService {
  static final MintService _instance = MintService._internal();
  factory MintService() => _instance;
  MintService._internal();

  static MintService get instance => _instance;

  /// Fetch mint information from server
  Future<MintInfo> fetchMintInfo(String mintUrl) async {
    try {
      final uri = Uri.parse(mintUrl);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch mint info: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return MintInfo.fromServerMap(data, mintUrl);
    } catch (e) {
      throw Exception('Failed to fetch mint info: $e');
    }
  }

  /// Fetch keysets from mint
  Future<List<KeysetInfo>> fetchKeysets(String mintUrl) async {
    try {
      final uri = Uri.parse('$mintUrl/keysets');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch keysets: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final keysets = <KeysetInfo>[];

      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          keysets.add(KeysetInfo.fromServerMap(value, mintUrl));
        }
      });

      return keysets;
    } catch (e) {
      throw Exception('Failed to fetch keysets: $e');
    }
  }

  /// Save mint info to database
  Future<void> saveMintInfo(MintInfo mintInfo) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.mintInfos.put(mintInfo);
    });
  }

  /// Save keyset info to database
  Future<void> saveKeysetInfo(KeysetInfo keysetInfo) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      await isar.keysetInfos.put(keysetInfo);
    });
  }

  /// Get all saved mints
  Future<List<MintInfo>> getAllMints() async {
    final isar = DatabaseService.isar;
    return await isar.mintInfos.where().findAll();
  }

  /// Get mint by URL
  Future<MintInfo?> getMintByUrl(String mintUrl) async {
    final isar = DatabaseService.isar;
    return await isar.mintInfos.where().mintURLEqualTo(mintUrl).findFirst();
  }

  /// Get all keysets for a mint
  Future<List<KeysetInfo>> getKeysetsForMint(String mintUrl) async {
    final isar = DatabaseService.isar;
    return await isar.keysetInfos.where().mintURLEqualTo(mintUrl).findAll();
  }

  /// Delete mint and its keysets
  Future<void> deleteMint(String mintUrl) async {
    final isar = DatabaseService.isar;
    await isar.writeTxn(() async {
      // Delete keysets first
      final keysets = await isar.keysetInfos.where().mintURLEqualTo(mintUrl).findAll();
      for (final keyset in keysets) {
        await isar.keysetInfos.delete(keyset.id);
      }
      
      // Delete mint
      final mint = await isar.mintInfos.where().mintURLEqualTo(mintUrl).findFirst();
      if (mint != null) {
        await isar.mintInfos.delete(mint.id);
      }
    });
  }

  /// Check if mint is reachable
  Future<bool> isMintReachable(String mintUrl) async {
    try {
      final uri = Uri.parse(mintUrl);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Request timeout'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Validate mint URL format
  bool isValidMintUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get mint status (online/offline)
  Future<MintStatus> getMintStatus(String mintUrl) async {
    try {
      final reachable = await isMintReachable(mintUrl);
      if (!reachable) {
        return MintStatus.offline;
      }

      final mintInfo = await fetchMintInfo(mintUrl);
      return MintStatus.online(mintInfo);
    } catch (e) {
      return MintStatus.error(e.toString());
    }
  }

  /// Sync mint data (fetch latest info and keysets)
  Future<void> syncMint(String mintUrl) async {
    try {
      // Fetch latest mint info
      final mintInfo = await fetchMintInfo(mintUrl);
      await saveMintInfo(mintInfo);

      // Fetch latest keysets
      final keysets = await fetchKeysets(mintUrl);
      for (final keyset in keysets) {
        await saveKeysetInfo(keyset);
      }
    } catch (e) {
      throw Exception('Failed to sync mint: $e');
    }
  }
}

/// Mint status enum
enum MintStatusType {
  online,
  offline,
  error,
}

/// Mint status
class MintStatus {
  final MintStatusType type;
  final MintInfo? mintInfo;
  final String? error;

  MintStatus(this.type, this.mintInfo, this.error);

  factory MintStatus.online(MintInfo mintInfo) => 
      MintStatus(MintStatusType.online, mintInfo, null);
  factory MintStatus.offline() => 
      MintStatus(MintStatusType.offline, null, null);
  factory MintStatus.error(String error) => 
      MintStatus(MintStatusType.error, null, error);

  bool get isOnline => type == MintStatusType.online;
  bool get isOffline => type == MintStatusType.offline;
  bool get hasError => type == MintStatusType.error;
}
