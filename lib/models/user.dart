import 'package:isar/isar.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';

part 'user.g.dart';

/// Login type enumeration
enum LoginType {
  nsec,    // Private key login
  bunker,  // Bunker server login
  signer,  // NostrSigner login
}

/// User model for Isar database
@collection
class User {
  Id id = Isar.autoIncrement;
  
  /// User's public key (hex format)
  @Index(unique: true)
  late String publicKey;
  
  /// User's display name
  late String displayName;
  
  /// Login type
  @Enumerated(EnumType.name)
  late LoginType loginType;
  
  /// Encrypted private key (stored in database)
  late String encryptedPrivateKey;
  
  /// Bunker server URL (for bunker login)
  String? bunkerUrl;
  
  /// NostrSigner app bundle ID (for signer login)
  String? signerBundleId;
  
  /// NostrSigner app name (for signer login)
  String? signerAppName;
  
  /// Creation timestamp
  late DateTime createdAt;
  
  /// Last login timestamp
  late DateTime lastLoginAt;
  
  /// Is this user currently active
  late bool isActive;
  
  /// User's relay list (JSON string)
  String? relays;
  
  /// User's mint list (JSON string)
  String? mints;
  
  User();
  
  User.create({
    required this.publicKey,
    required this.displayName,
    required this.loginType,
    required this.encryptedPrivateKey,
    this.bunkerUrl,
    this.signerBundleId,
    this.signerAppName,
    this.relays,
    this.mints,
  }) : createdAt = DateTime.now(),
       lastLoginAt = DateTime.now(),
       isActive = true;
  
  /// Update last login time
  void updateLastLogin() {
    lastLoginAt = DateTime.now();
  }
  
  /// Set user as active
  void setActive() {
    isActive = true;
    updateLastLogin();
  }
  
  /// Set user as inactive
  void setInactive() {
    isActive = false;
  }
  
  /// Get user's relay list as List<String>
  List<String> getRelays() {
    if (relays == null || relays!.isEmpty) return [];
    try {
      return relays!.split(',').where((r) => r.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Set user's relay list from List<String>
  void setRelays(List<String> relayList) {
    relays = relayList.join(',');
  }
  
  /// Get user's mint list as List<String>
  List<String> getMints() {
    if (mints == null || mints!.isEmpty) return [];
    try {
      return mints!.split(',').where((m) => m.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Set user's mint list from List<String>
  void setMints(List<String> mintList) {
    mints = mintList.join(',');
  }
  
  /// Convert hex public key to npub format
  String get npub {
    try {
      return publicKeyToNpub(publicKey: publicKey);
    } catch (e) {
      return publicKey; // Return original if conversion fails
    }
  }
  
  /// Get display name or fallback to npub prefix
  String get displayNameOrNpub {
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return 'User ${npub.substring(0, 8)}';
  }
}
