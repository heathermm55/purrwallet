import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:isar/isar.dart';
import '../models/user.dart';
import '../../db/database_service.dart';

/// User service for managing user data and encryption
class UserService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Generate a strong random password
  static String _generateStrongPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    final password = StringBuffer();
    
    // Generate 32 character password
    for (int i = 0; i < 32; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }
    
    return password.toString();
  }
  
  /// Generate encryption key from password
  static String _generateKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32); // Use first 32 characters
  }
  
  /// Encrypt private key with password
  static String encryptPrivateKey(String privateKey, String password) {
    final key = _generateKey(password);
    final iv = IV.fromLength(16); // Generate random IV
    final encrypter = Encrypter(AES(Key.fromBase64(base64.encode(utf8.encode(key)))));
    final encrypted = encrypter.encrypt(privateKey, iv: iv);
    // Combine IV and encrypted data
    return base64.encode(iv.bytes + encrypted.bytes);
  }
  
  /// Decrypt private key with password
  static String decryptPrivateKey(String encryptedPrivateKey, String password) {
    final key = _generateKey(password);
    final encrypter = Encrypter(AES(Key.fromBase64(base64.encode(utf8.encode(key)))));
    
    // Decode the combined IV + encrypted data
    final combined = base64.decode(encryptedPrivateKey);
    final iv = IV(combined.sublist(0, 16)); // First 16 bytes are IV
    final encrypted = Encrypted(combined.sublist(16)); // Rest is encrypted data
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
  
  /// Save encryption password to secure storage
  static Future<void> saveEncryptionPassword(String userId, String password) async {
    await _secureStorage.write(key: 'encryption_password_$userId', value: password);
  }
  
  /// Get encryption password from secure storage
  static Future<String?> getEncryptionPassword(String userId) async {
    return await _secureStorage.read(key: 'encryption_password_$userId');
  }
  
  /// Delete encryption password from secure storage
  static Future<void> deleteEncryptionPassword(String userId) async {
    await _secureStorage.delete(key: 'encryption_password_$userId');
  }
  
  /// Create new user with auto-generated password
  static Future<User> createUser({
    required String publicKey,
    required String displayName,
    required LoginType loginType,
    required String privateKey,
    String? bunkerUrl,
    String? signerBundleId,
    String? signerAppName,
    List<String>? relays,
    List<String>? mints,
  }) async {
    // Ensure user database is open
    await DatabaseService.openUserDatabase(publicKey);
    
    // Generate strong password automatically
    final password = _generateStrongPassword();
    
    // Encrypt private key
    final encryptedPrivateKey = encryptPrivateKey(privateKey, password);
    
    // Save password to secure storage
    await saveEncryptionPassword(publicKey, password);
    
    // Create user
    final user = User.create(
      publicKey: publicKey,
      displayName: displayName,
      loginType: loginType,
      encryptedPrivateKey: encryptedPrivateKey,
      bunkerUrl: bunkerUrl,
      signerBundleId: signerBundleId,
      signerAppName: signerAppName,
    );
    
    if (relays != null) {
      user.setRelays(relays);
    }
    
    if (mints != null) {
      user.setMints(mints);
    }
    
    // Save to database
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.users.put(user);
    });
    
    return user;
  }
  
  /// Get user by public key
  static Future<User?> getUserByPublicKey(String publicKey) async {
    await DatabaseService.openUserDatabase(publicKey);
    return await DatabaseService.isar.users.where().publicKeyEqualTo(publicKey).findFirst();
  }
  
  /// Get active user
  static Future<User?> getActiveUser() async {
    // For active user, we need to check all user databases
    // This is a simplified implementation - in practice you might want to store active user info globally
    return await DatabaseService.isar.users.where().filter().isActiveEqualTo(true).findFirst();
  }
  
  /// Get all users
  static Future<List<User>> getAllUsers() async {
    return await DatabaseService.isar.users.where().findAll();
  }
  
  /// Update user
  static Future<void> updateUser(User user) async {
    await DatabaseService.openUserDatabase(user.publicKey);
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.users.put(user);
    });
  }
  
  /// Delete user
  static Future<void> deleteUser(User user) async {
    await DatabaseService.openUserDatabase(user.publicKey);
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.users.delete(user.id);
    });
    
    // Also delete encryption password
    await deleteEncryptionPassword(user.publicKey);
  }
  
  /// Set active user
  static Future<void> setActiveUser(String publicKey) async {
    await DatabaseService.openUserDatabase(publicKey);
    
    // First, deactivate all users in current database
    final allUsers = await getAllUsers();
    for (final user in allUsers) {
      user.setInactive();
      await updateUser(user);
    }
    
    // Then activate the specified user
    final user = await getUserByPublicKey(publicKey);
    if (user != null) {
      user.setActive();
      await updateUser(user);
    }
  }
  
  /// Verify password for user
  static Future<bool> verifyPassword(String publicKey, String password) async {
    try {
      final user = await getUserByPublicKey(publicKey);
      if (user == null) return false;
      
      decryptPrivateKey(user.encryptedPrivateKey, password);
      return true;
    } catch (e) {
      return false;
    }
  }
}
