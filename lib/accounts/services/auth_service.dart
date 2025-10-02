import 'package:rust_plugin/src/rust/api/nostr.dart';
import '../models/user.dart';
import 'user_service.dart';

/// User authentication service
class AuthService {
  static User? _currentUser;
  
  /// Get current logged in user
  static User? get currentUser => _currentUser;
  
  /// Set current user (for auto-login)
  static void setCurrentUser(User user) {
    _currentUser = user;
  }
  
  /// Initialize auth service
  static Future<void> init() async {
    // Any initial setup for auth service if needed
  }
  
  /// Login with private key (nsec or hex) - password auto-generated
  static Future<User?> loginWithPrivateKey({
    required String privateKey,
    String? displayName,
  }) async {
    try {
      String hexPrivateKey;
      
      // Check if input is nsec format
      if (privateKey.startsWith('nsec')) {
        hexPrivateKey = nsecToSecretKey(nsec: privateKey);
      } else {
        // Assume it's hex format
        hexPrivateKey = privateKey;
      }
      
      // Get public key (hex format)
      final publicKey = getPublicKeyFromPrivate(privateKey: hexPrivateKey);
      
      // Check if user already exists
      User? user = await UserService.getUserByPublicKey(publicKey);
      
      if (user != null) {
        // Set as active user
        await UserService.setActiveUser(publicKey);
        user.setActive();
        await UserService.updateUser(user);
        
        _currentUser = user;
        return user;
      } else {
        // Create new user with auto-generated password
        user = await UserService.createUser(
          publicKey: publicKey,
          displayName: displayName ?? 'User ${publicKey.substring(0, 8)}',
          loginType: LoginType.nsec,
          privateKey: hexPrivateKey,
        );
        
        _currentUser = user;
        return user;
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  /// Login with NostrSigner
  static Future<User?> loginWithNostrSigner({
    required String signerBundleId,
    required String signerAppName,
    String? displayName,
  }) async {
    try {
      // TODO: Implement actual NostrSigner connection
      // This would typically involve:
      // 1. Connecting to the NostrSigner app
      // 2. Requesting public key
      // 3. Setting up signing capabilities
      
      // For now, generate a mock public key
      final keys = generateKeys();
      final publicKey = keys.publicKey; // Use hex format
      
      // Check if user already exists
      User? user = await UserService.getUserByPublicKey(publicKey);
      
      if (user != null) {
        // Update signer info
        user.signerBundleId = signerBundleId;
        user.signerAppName = signerAppName;
        await UserService.setActiveUser(publicKey);
        user.setActive();
        await UserService.updateUser(user);
        
        _currentUser = user;
        return user;
      } else {
        // Create new user
        user = await UserService.createUser(
          publicKey: publicKey,
          displayName: displayName ?? 'NostrSigner User',
          loginType: LoginType.signer,
          privateKey: '', // No private key stored for signer
          signerBundleId: signerBundleId,
          signerAppName: signerAppName,
        );
        
        _currentUser = user;
        return user;
      }
    } catch (e) {
      throw Exception('NostrSigner login failed: $e');
    }
  }
  
  /// Login with Bunker server
  static Future<User?> loginWithBunker({
    required String bunkerUrl,
    required String publicKey,
    String? displayName,
  }) async {
    try {
      // Use public key in hex format directly
      
      // Check if user already exists
      User? user = await UserService.getUserByPublicKey(publicKey);
      
      if (user != null) {
        // Update bunker info
        user.bunkerUrl = bunkerUrl;
        await UserService.setActiveUser(publicKey);
        user.setActive();
        await UserService.updateUser(user);
        
        _currentUser = user;
        return user;
      } else {
        // Create new user
        user = await UserService.createUser(
          publicKey: publicKey,
          displayName: displayName ?? 'Bunker User',
          loginType: LoginType.bunker,
          privateKey: '', // No private key stored for bunker
          bunkerUrl: bunkerUrl,
        );
        
        _currentUser = user;
        return user;
      }
    } catch (e) {
      throw Exception('Bunker login failed: $e');
    }
  }
  
  /// Logout current user
  static Future<void> logout() async {
    if (_currentUser != null) {
      _currentUser!.setInactive();
      await UserService.updateUser(_currentUser!);
      _currentUser = null;
    }
  }
  
  /// Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
}
