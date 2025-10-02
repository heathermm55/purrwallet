import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../accounts/models/user.dart';

/// Basic database service for managing Isar database
class DatabaseService {
  static Isar? _isar;

  /// Initialize Isar database
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [UserSchema],
      directory: dir.path,
    );
  }

  /// Get Isar instance
  static Isar get isar {
    if (_isar == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() first.');
    }
    return _isar!;
  }

  /// Close database
  static Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }

  /// Check if database is initialized
  static bool get isInitialized => _isar != null;
}
