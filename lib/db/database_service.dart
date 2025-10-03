import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../accounts/models/user.dart';

/// Basic database service for managing Isar database
class DatabaseService {
  static Isar? _isar;
  static String? _currentPubkey;

  /// Initialize Isar database
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserSchema,
      ],
      directory: dir.path,
    );
  }

  /// Generate database name for given pubkey
  static String _getDatabaseName(String pubkey) {
    return pubkey;
  }

  /// Get database directory path
  static Future<String> _getDatabaseDirectory() async {
    bool isOS = Platform.isIOS || Platform.isMacOS;
    Directory directory = isOS ? await getLibraryDirectory() : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get full database file path
  static Future<String> _getDatabaseFilePath(String pubkey) async {
    final dbName = _getDatabaseName(pubkey);
    final dbDir = await _getDatabaseDirectory();
    return '$dbDir/$dbName.isar';
  }

  /// Open database for specific user
  static Future<void> openUserDatabase(String pubkey) async {
    if (_currentPubkey == pubkey && _isar != null) {
      return; // Already open for this user
    }

    // Close current database if different user
    if (_isar != null && _currentPubkey != pubkey) {
      await _isar!.close();
      _isar = null;
    }

    final dbName = _getDatabaseName(pubkey);
    final dbDir = await _getDatabaseDirectory();
    
    _isar = Isar.getInstance(dbName) ??
        await Isar.open(
          [
            UserSchema,
          ],
          directory: dbDir,
          name: dbName,
        );
    
    _currentPubkey = pubkey;
  }

  /// Get Isar instance
  static Isar get isar {
    if (_isar == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() or openUserDatabase() first.');
    }
    return _isar!;
  }

  /// Close database
  static Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _currentPubkey = null;
    }
  }

  /// Check if database is initialized
  static bool get isInitialized => _isar != null;

  /// Get current user pubkey
  static String? get currentPubkey => _currentPubkey;
}
