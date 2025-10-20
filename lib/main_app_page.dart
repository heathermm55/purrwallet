import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'accounts/services/auth_service.dart';
import 'accounts/services/user_service.dart';
import 'dart:math';
import 'settings/main_settings_page.dart';
import 'wallet/services/wallet_service.dart';

/// Main app page - Wallet interface
class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  
  // Cashu Wallet state
  WalletInfo? _walletInfo;
  List<TransactionInfo> _transactions = [];
  
  // Secure storage for seed
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  @override
  void initState() {
    super.initState();
    _initializeWallet();
    _setupUICallbacks();
  }

  /// Setup UI callbacks for monitoring updates
  void _setupUICallbacks() {
    // Set up callback for UI updates
    WalletService.onMintedAmountReceived = (Map<String, String> result) {
      if (mounted) {
        final totalMinted = int.parse(result['total_minted'] ?? '0');
        if (totalMinted > 0) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment received! $totalMinted sats minted to wallet',
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh wallet data
          _refreshWalletData();
        }
      }
    };

    // Set up callback for melt quote updates
    WalletService.onMeltedAmountReceived = (Map<String, String> result) {
      if (mounted) {
        final completedCount = int.parse(result['completed_count'] ?? '0');
        if (completedCount > 0) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment sent! $completedCount melt quotes completed',
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh wallet data
          _refreshWalletData();
        }
      }
    };
  }

  /// Generate a new 32-byte seed as hex string
  String _generateSeedHex() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get or create seed from secure storage
  Future<String> _getOrCreateSeed() async {
    try {
      // Try to get existing seed
      final existingSeed = await _secureStorage.read(key: _seedKey);
      if (existingSeed != null && existingSeed.length == 64) {
        print('Using existing seed from secure storage');
        return existingSeed;
      }
    } catch (e) {
      print('Error reading seed from storage: $e');
    }

    // Generate new seed if none exists or invalid
    final newSeed = _generateSeedHex();
    try {
      await _secureStorage.write(key: _seedKey, value: newSeed);
      print('Generated and stored new seed');
    } catch (e) {
      print('Error storing seed: $e');
    }
    
    return newSeed;
  }

  Future<void> _initializeWallet() async {
    try {
      // Get or create seed from secure storage
      final seedHex = await _getOrCreateSeed();
      print('Using seed: ${seedHex.substring(0, 8)}...');

      // Initialize wallet using WalletService (this will automatically start monitoring)
      final initResult = await WalletService.initializeWallet(seedHex);
      print('Wallet initialization result: $initResult');

      // Load wallet data if mints are available
      await _refreshWalletData();
    } catch (e) {
      print('Wallet initialization error: $e');
    }
  }

  String _formatBalance(String balance) {
    try {
      final amount = int.parse(balance);
      if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}k';
      }
      return amount.toString();
    } catch (e) {
      return '0';
    }
  }

  Widget _buildUserAvatar() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(
        Icons.person,
        color: Color(0xFF00FF00),
        size: 24,
      ),
    );
  }

  void _showAccountMenuDialog() {
    final currentUser = AuthService.currentUser;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Account',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentUser != null) ...[
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF00FF00)),
                  title: const Text(
                    'Account Info',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAccountInfoDialog();
                  },
                ),
                const Divider(color: Color(0xFF333333)),
              ],
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF00FF00)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountInfoDialog() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Account Info',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Public Key (npub):',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                currentUser.npub,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Private Key (nsec):',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _getNsec(currentUser),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    return SelectableText(
                      snapshot.data!,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  } else {
                    return const Text(
                      'Unable to decrypt private key',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Login Type:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentUser.loginType.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getNsec(currentUser) async {
    try {
      final password = await UserService.getEncryptionPassword(currentUser.publicKey);
      if (password == null) return null;
      
      final decryptedPrivateKey = UserService.decryptPrivateKey(currentUser.encryptedPrivateKey, password);
      return secretKeyToNsec(secretKey: decryptedPrivateKey);
    } catch (e) {
      return null;
    }
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF00FF00)),
                title: const Text(
                  'Mints',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Manage mint servers',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showMintsDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF00FF00)),
                title: const Text(
                  'Security',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Seed phrase and restore options',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSecurityDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.network_check, color: Color(0xFF00FF00)),
                title: const Text(
                  'Network',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Proxy and Tor settings',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showNetworkDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF00FF00)),
                title: const Text(
                  'About',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'App information',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAboutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Validate mint URL to support various protocols and address types
  bool _isValidMintUrl(String url) {
    if (url.isEmpty) return false;
    
    // Remove trailing slashes
    url = url.trim().replaceAll(RegExp(r'/+$'), '');
    
    // Check for supported protocols
    final supportedProtocols = ['http', 'https'];
    final hasProtocol = supportedProtocols.any((protocol) => url.toLowerCase().startsWith('$protocol://'));
    
    if (!hasProtocol) {
      // If no protocol specified, assume https
      url = 'https://$url';
    }
    
    try {
      final uri = Uri.parse(url);
      
      // Check if it's a valid URI
      if (!uri.hasScheme || !uri.hasAuthority) return false;
      
      // Validate scheme
      if (!supportedProtocols.contains(uri.scheme.toLowerCase())) return false;
      
      // Check for various address types
      final host = uri.host.toLowerCase();
      
      // Local addresses
      if (host == 'localhost' || host == '127.0.0.1') return true;
      
      // Private network ranges
      if (host.startsWith('192.168.') || 
          host.startsWith('10.') || 
          host.startsWith('172.')) {
        return true;
      }
      
      // Tor .onion addresses
      if (host.endsWith('.onion')) return true;
      
      // Regular domain names (must contain at least one dot)
      if (host.contains('.') && !host.startsWith('.') && !host.endsWith('.')) return true;
      
      // IP addresses (IPv4)
      final ipv4Regex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
      if (ipv4Regex.hasMatch(host)) {
        final parts = host.split('.');
        for (final part in parts) {
          final num = int.tryParse(part);
          if (num == null || num < 0 || num > 255) return false;
        }
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showMintsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Mints',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<List<String>>(
            future: Future(() => listMints()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading mints...',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }
              
              final mints = snapshot.data ?? [];
              
              if (mints.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No mints configured',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add new mint:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter mint URL',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Show current mints list
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Mints:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...mints.map((mint) {
                      final parts = mint.split(':');
                      final mintUrl = parts.isNotEmpty ? parts[0] : mint;
                      final unit = parts.length > 1 ? parts[1] : 'sat';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _showMintDetailDialog(mintUrl, 'Mint');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF00FF00)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Color(0xFF00FF00), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mintUrl,
                                        style: TextStyle(
                                          color: Color(0xFF00FF00),
                                          fontFamily: 'Courier',
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Unit: $unit',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontFamily: 'Courier',
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Text(
                      'Add new mint:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter mint URL',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddMintDialog();
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddMintDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController aliasController = TextEditingController();
    String? urlError;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Add New Mint',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mint URL:',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://mint.example.com or localhost:3338',
                      hintStyle: const TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      errorText: urlError,
                      errorStyle: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final isValid = _isValidMintUrl(value);
                        setState(() {
                          urlError = isValid ? null : 'Invalid URL format';
                        });
                      } else {
                        setState(() {
                          urlError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alias (optional):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aliasController,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'My Local Mint',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supported formats:',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• HTTPS: https://mint.example.com\n'
                    '• HTTP: http://localhost:3338\n'
                    '• Local: localhost:3338 or 127.0.0.1:3338\n'
                    '• LAN: 192.168.1.100:3338\n'
                    '• Tor: abc123def.onion:3338',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    var url = urlController.text.trim();
                    final alias = aliasController.text.trim();
                    
                    if (url.isEmpty) {
                      setState(() {
                        urlError = 'URL is required';
                      });
                      return;
                    }
                    
                    if (!_isValidMintUrl(url)) {
                      setState(() {
                        urlError = 'Invalid URL format';
                      });
                      return;
                    }
                    
                    // Add https:// if no protocol specified
                    if (!url.toLowerCase().startsWith('http://') && 
                        !url.toLowerCase().startsWith('https://')) {
                      url = 'https://$url';
                    }
                    
                    // Add the mint
                    Navigator.of(context).pop();
                    _addMint(url, alias.isNotEmpty ? alias : 'Mint');
                  },
                  child: const Text(
                    'Add Mint',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMint(String mintUrl, String alias) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Adding mint...',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: Color(0xFF1A1A1A),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Add the mint using the Rust API (with await!)
      final result = await addMint(mintUrl: mintUrl);
      print('Add mint result: $result');
      
      // Refresh wallet data after adding mint
      await _refreshWalletData();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mint added successfully: $alias',
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Reopen mints dialog to show updated list
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showMintsDialog();
          }
        });
      }
    } catch (e) {
      print('Failed to add mint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add mint: $e',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showMintDetailDialog(String mintUrl, String alias) {
    final TextEditingController aliasController = TextEditingController(text: alias);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Mint Details',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mint URL:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                mintUrl,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alias:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aliasController,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter alias for this mint',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteMintConfirmation(mintUrl, aliasController.text);
                      },
                      icon: const Icon(Icons.delete, color: Color(0xFFFF6B6B), size: 16),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFFF6B6B)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMintAlias(mintUrl, aliasController.text);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMintConfirmation(String mintUrl, String alias) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Mint',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this mint?',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Alias: $alias',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              Text(
                'URL: $mintUrl',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMint(mintUrl);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateMintAlias(String mintUrl, String newAlias) {
    // TODO: Update mint alias in storage
    print('Updating mint alias: $mintUrl -> $newAlias');
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mint alias updated to: $newAlias',
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteMint(String mintUrl) {
    // TODO: Delete mint from storage
    print('Deleting mint: $mintUrl');
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mint deleted: $mintUrl',
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Security',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Color(0xFF00FF00)),
                title: const Text(
                  'View Seed Phrase',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Display wallet seed phrase',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSeedPhraseDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.restore, color: Color(0xFF00FF00)),
                title: const Text(
                  'Restore Wallet',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Restore from backup',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showRestoreDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSeedPhraseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Seed Phrase',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your wallet seed phrase:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: _getSeedHex(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  } else if (snapshot.hasData) {
                    return SelectableText(
                      snapshot.data!,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  } else {
                    return const Text(
                      'Unable to load seed',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Keep this seed phrase secure!',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Restore Wallet',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your seed phrase:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Paste your seed phrase here...',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will restore your wallet from backup.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Restore wallet functionality
              },
              child: const Text(
                'Restore',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNetworkDialog() {
    bool isTorEnabled = false;
    bool isProxyEnabled = false;
    String proxyHost = '';
    String proxyPort = '';
    String proxyUsername = '';
    String proxyPassword = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Network Settings',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tor Mode
                    Row(
                      children: [
                        Checkbox(
                          value: isTorEnabled,
                          onChanged: (value) {
                            setState(() {
                              isTorEnabled = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF00FF00),
                          checkColor: Colors.black,
                        ),
                        const Text(
                          'Tor Mode',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Route all traffic through Tor network',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Proxy Settings
                    Row(
                      children: [
                        Checkbox(
                          value: isProxyEnabled,
                          onChanged: (value) {
                            setState(() {
                              isProxyEnabled = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF00FF00),
                          checkColor: Colors.black,
                        ),
                        const Text(
                          'Proxy Settings',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    if (isProxyEnabled) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Proxy Host:',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (value) => proxyHost = value,
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                        ),
                        decoration: const InputDecoration(
                          hintText: '127.0.0.1',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Proxy Port:',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (value) => proxyPort = value,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                        ),
                        decoration: const InputDecoration(
                          hintText: '8080',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Username (optional):',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (value) => proxyUsername = value,
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'proxy_user',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Password (optional):',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (value) => proxyPassword = value,
                        obscureText: true,
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'proxy_pass',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00FF00)),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    const Text(
                      '⚠️ Network settings will be applied after app restart',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveNetworkSettings(
                      isTorEnabled,
                      isProxyEnabled,
                      proxyHost,
                      proxyPort,
                      proxyUsername,
                      proxyPassword,
                    );
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveNetworkSettings(
    bool isTorEnabled,
    bool isProxyEnabled,
    String proxyHost,
    String proxyPort,
    String proxyUsername,
    String proxyPassword,
  ) {
    // TODO: Save network settings to storage
    print('Saving network settings:');
    print('  Tor enabled: $isTorEnabled');
    print('  Proxy enabled: $isProxyEnabled');
    if (isProxyEnabled) {
      print('  Proxy host: $proxyHost');
      print('  Proxy port: $proxyPort');
      print('  Proxy username: $proxyUsername');
      print('  Proxy password: ${proxyPassword.isNotEmpty ? '[HIDDEN]' : '[EMPTY]'}');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Network settings saved. Restart app to apply changes.',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'About PurrWallet',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PurrWallet v1.0.0',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cross-platform ecash wallet',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Built with Flutter & Rust',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'IRC-style interface',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Nostr account integration',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
              const Text(
                '• Cashu wallet support',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
              const Text(
                '• Multi-mint support',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
              const Text(
                '• Secure key storage',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getSeedHex() async {
    try {
      return await _secureStorage.read(key: _seedKey) ?? 'No seed found';
    } catch (e) {
      return 'Error loading seed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PURRWALLET',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF00FF00),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Wallet Cards Section
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: _buildWalletCard(
                    'Local Wallet',
                    _walletInfo != null ? '${_formatBalance(_walletInfo!.balance.toString())} sats' : '0 sats',
                    null, // No USD display
                    const LinearGradient(
                      colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                    ),
                    Icons.flash_on,
                  ),
                ),
              ),
              
              // Transaction History Section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TRANSACTION',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: _showAllTransactionsDialog,
                        child: const Text(
                          'VIEW ALL',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: const SizedBox(height: 16),
              ),
              
              // Transaction List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTransactionItem(index),
                    );
                  },
                    childCount: _transactions.length, // Match the number of transactions in the array
                ),
              ),
              
              // Add bottom padding to account for floating navigation
              SliverToBoxAdapter(
                child: const SizedBox(height: 100),
              ),
            ],
          ),
          // Floating bottom navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFF00FF00), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavButton('Receive', Icons.keyboard_arrow_down, onTap: _showReceiveOptions),
                  _buildBottomNavButton('Scan', Icons.qr_code_scanner, onTap: _showScanDialog),
                  _buildBottomNavButton('Send', Icons.keyboard_arrow_up, onTap: _showSendOptions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(String title, String sats, String? usd, Gradient gradient, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Icon(
                icon,
                color: const Color(0xFF00FF00),
                size: 32,
              ),
            ],
          ),
          const Spacer(),
          Text(
            sats,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (usd != null)
            Text(
              usd,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTransactionItem(int index) {
    if (index >= _transactions.length) {
      return const SizedBox.shrink();
    }
    
    final tx = _transactions[index];
    final isReceived = tx.direction == 'incoming';
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestamp.toInt());
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return InkWell(
      onTap: () => _showTransactionDetailDialog(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isReceived ? Colors.green : Colors.red).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceived ? Icons.arrow_upward : Icons.arrow_downward,
              color: isReceived ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.memo ?? (isReceived ? 'Received' : 'Sent'),
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isReceived ? 'Lightning Receive' : 'Ecash Payment',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isReceived ? '+' : '-'}${tx.amount} sats',
                style: TextStyle(
                  color: isReceived ? Colors.green : Colors.red,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '~\$0.00',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildBottomNavButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF00FF00),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Receive',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_paste, color: Color(0xFF00FF00)),
                title: const Text(
                  'Ecash',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Paste Cashu token from clipboard',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEcashReceiveDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.flash_on, color: Color(0xFF00FF00)),
                title: const Text(
                  'Lightning',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Receive ecash by paying a lightning invoice',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLightningReceiveDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEcashReceiveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Receive Ecash',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste Cashu token from clipboard:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste your Cashu token here...',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Paste from clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Paste from clipboard functionality coming soon',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                              ),
                            ),
                            backgroundColor: Color(0xFF1A1A1A),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.content_paste, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Process ecash token
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ecash token processing coming soon',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                    ),
                    backgroundColor: Color(0xFF1A1A1A),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Receive',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLightningReceiveDialog() async {
    // Check if there are any mints available first
    final mints = await listMints();
    if (mints.isEmpty) {
      // Show dialog to prompt user to add a mint
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'No Mints Available',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You need to add a mint first before you can receive via lightning.',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Would you like to add a mint now?',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddMintDialog();
                },
                child: const Text(
                  'Add Mint',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    
    // If mints are available, show the lightning receive dialog
    final amountController = TextEditingController();
    
    // Parse mint strings to get display names
    final mintList = mints.map((mint) {
      // Format: "mint_url:unit"
      final lastColonIndex = mint.lastIndexOf(':');
      if (lastColonIndex != -1) {
        return mint.substring(0, lastColonIndex);
      }
      return mint;
    }).toList();
    
    // Default selected mint (first one)
    String selectedMint = mintList.first;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Receive via Lightning',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Mint:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: selectedMint,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
                        hint: const Text(
                          'Default Mint',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                          ),
                        ),
                        items: mintList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final mint = entry.value;
                          final displayName = index == 0 ? 'Default Mint ($mint)' : mint;
                          return DropdownMenuItem<String>(
                            value: mint,
                            child: Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedMint = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter amount to receive:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter amount in sats',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This will create a lightning invoice that you can pay to receive ecash tokens.',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final amountText = amountController.text.trim();
                    
                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter an amount',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontFamily: 'Courier',
                            ),
                          ),
                          backgroundColor: Color(0xFF1A1A1A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final amount = int.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid amount',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontFamily: 'Courier',
                            ),
                          ),
                          backgroundColor: Color(0xFF1A1A1A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    await _createLightningInvoice(amount, mintUrl: selectedMint);
                  },
                  child: const Text(
                    'Create Invoice',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Create a lightning invoice using new simplified API
  Future<void> _createLightningInvoice(int amount, {String? mintUrl}) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Creating lightning invoice...',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Use provided mint URL or get the first available mint
      String? selectedMintUrl = mintUrl;
      
      if (selectedMintUrl == null) {
        final mints = await listMints();
        if (mints.isEmpty) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No mints available. Please add a mint first.',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontFamily: 'Courier',
                ),
              ),
              backgroundColor: Color(0xFF1A1A1A),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Extract mint URL from format "mint_url:unit" (e.g., "http://127.0.0.1:3338:sat")
        final mintString = mints.first;
        final lastColonIndex = mintString.lastIndexOf(':');
        selectedMintUrl = lastColonIndex != -1 
            ? mintString.substring(0, lastColonIndex)
            : mintString;
      }
      
      print('Creating lightning invoice for mint: $selectedMintUrl');

      // Create mint quote using new simplified API
      final quote = await createMintQuote(
        mintUrl: selectedMintUrl,
        amount: BigInt.from(amount),
      );

      final invoice = quote['request']!;
      final invoiceAmount = int.parse(quote['amount']!);

      Navigator.of(context).pop(); // Close loading dialog

      // Start specific monitoring for this mint URL
      WalletService.startMintQuoteMonitoring([selectedMintUrl]);

      // Show invoice dialog
      _showInvoiceDialog(invoice, invoiceAmount, selectedMintUrl);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create lightning invoice: $e',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show lightning invoice dialog and start monitoring automatically
  void _showInvoiceDialog(String invoice, int amount, String mintUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Lightning Invoice Created',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: $amount sats',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // QR Code display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF00FF00), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: invoice.toUpperCase(),
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFF00FF00),
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invoice:',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: invoice));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invoice copied to clipboard!',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                          ),
                        ),
                        backgroundColor: Color(0xFF1A1A1A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00FF00)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.copy,
                        color: Color(0xFF00FF00),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this invoice with the sender to receive payment.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
              ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    // Set up callback for payment received
    WalletService.onMintedAmountReceived = (result) {
      final mintedAmount = int.parse(result['total_minted'] ?? '0');
      if (mintedAmount > 0 && mounted) {
        _showPaymentSuccess(mintedAmount);
        WalletService.stopMintQuoteMonitoring();
      }
    };
    
    // Start monitoring using WalletService
    WalletService.startMintQuoteMonitoring([mintUrl]);
  }

  void _showScanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Scan QR Code',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFF00FF00),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan QR Code',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan a Cashu token or Lightning invoice',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startQRScanner();
                      },
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Start Scanner',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showManualInputDialog();
                      },
                      icon: const Icon(Icons.keyboard, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Manual Input',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startQRScanner() {
    // TODO: Implement QR scanner using camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'QR Scanner functionality coming soon',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Manual Input',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter QR code content:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste Cashu token or Lightning invoice...',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Paste from clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Paste from clipboard functionality coming soon',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                              ),
                            ),
                            backgroundColor: Color(0xFF1A1A1A),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.content_paste, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processScannedContent(controller.text);
              },
              child: const Text(
                'Process',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processScannedContent(String content) {
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter content to process',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // TODO: Process scanned content (Cashu token or Lightning invoice)
    print('Processing scanned content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
    
    // Determine content type and process accordingly
    if (content.startsWith('cashuA') || content.startsWith('cashu1')) {
      // Cashu token
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Processing Cashu token...',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (content.startsWith('lnbc') || content.startsWith('lightning:')) {
      // Lightning invoice
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Processing Lightning invoice...',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Unknown format
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unknown content format',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSendOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Send',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.send, color: Color(0xFF00FF00)),
                title: const Text(
                  'Ecash',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Create Cashu token and share',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEcashSendDialog();
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.flash_on, color: Color(0xFF00FF00)),
                title: const Text(
                  'Lightning',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Withdraw funds by paying invoice',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLightningSendDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEcashSendDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController memoController = TextEditingController();
    String selectedMint = '';
    String selectedMintAlias = 'No Mint Selected';
    bool isP2PKEnabled = false;
    String? p2pkPubkey;
    String? p2pkSigFlags;
    String? p2pkNSig;
    String? p2pkLockTime;
    String? p2pkRefund;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Send Ecash',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Mint
                    const Text(
                      'Selected Mint:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showMintSelectionDialog((mintUrl, alias) {
                          selectedMint = mintUrl;
                          selectedMintAlias = alias;
                          _showEcashSendDialog();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF00FF00)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFF00FF00), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedMintAlias,
                                    style: const TextStyle(
                                      color: Color(0xFF00FF00),
                                      fontFamily: 'Courier',
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    selectedMint,
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount
                    const Text(
                      'Sats Amount:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 18,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'Description:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: memoController,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'This is Description',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00FF00)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // P2PK Options
                    Row(
                      children: [
                        Checkbox(
                          value: isP2PKEnabled,
                          onChanged: (value) {
                            setState(() {
                              isP2PKEnabled = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF00FF00),
                          checkColor: Colors.black,
                        ),
                        const Text(
                          'P2PK',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    if (isP2PKEnabled) ...[
                      const SizedBox(height: 8),
                      _buildP2PKOption('Pubkey', p2pkPubkey, (value) => p2pkPubkey = value),
                      const SizedBox(height: 8),
                      _buildP2PKOption('SigFlags', p2pkSigFlags, (value) => p2pkSigFlags = value),
                      const SizedBox(height: 8),
                      _buildP2PKOption('N_sig', p2pkNSig, (value) => p2pkNSig = value),
                      const SizedBox(height: 8),
                      _buildP2PKOption('LockTime', p2pkLockTime, (value) => p2pkLockTime = value),
                      const SizedBox(height: 8),
                      _buildP2PKOption('Refund', p2pkRefund, (value) => p2pkRefund = value),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _createEcashToken(
                      amountController.text,
                      memoController.text,
                      selectedMint,
                      isP2PKEnabled,
                      p2pkPubkey,
                      p2pkSigFlags,
                      p2pkNSig,
                      p2pkLockTime,
                      p2pkRefund,
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildP2PKOption(String label, String? value, Function(String?) onChanged) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _showP2PKOptionDialog(label, value ?? 'None', onChanged);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF00FF00)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              value ?? 'None',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 12),
          ],
        ),
      ),
    );
  }

  void _showMintSelectionDialog(Function(String, String) onMintSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Select Mint',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF00FF00)),
                title: const Text(
                  'Local Mint',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'No default mint available',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // No default mint to select
                },
              ),
              const Divider(color: Color(0xFF333333)),
              ListTile(
                leading: const Icon(Icons.add, color: Color(0xFF00FF00)),
                title: const Text(
                  'Add New Mint',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: const Text(
                  'Add a custom mint server',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Show add mint dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Add mint functionality coming soon',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                        ),
                      ),
                      backgroundColor: Color(0xFF1A1A1A),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showP2PKOptionDialog(String label, String currentValue, Function(String?) onChanged) {
    final TextEditingController controller = TextEditingController(text: currentValue == 'None' ? '' : currentValue);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Set $label',
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                decoration: InputDecoration(
                  hintText: 'Enter $label value',
                  hintStyle: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onChanged(null);
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onChanged(controller.text.isEmpty ? null : controller.text);
              },
              child: const Text(
                'Set',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLightningSendDialog() {
    final TextEditingController invoiceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Send via Lightning',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lightning Invoice:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: invoiceController,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Paste lightning invoice here...',
                  hintStyle: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Paste from clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Paste from clipboard functionality coming soon',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                              ),
                            ),
                            backgroundColor: Color(0xFF1A1A1A),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.content_paste, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This will withdraw your ecash funds by paying the lightning invoice.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _payLightningInvoice(invoiceController.text);
              },
              child: const Text(
                'Pay Invoice',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createEcashToken(
    String amount,
    String memo,
    String mintUrl,
    bool isP2PKEnabled,
    String? p2pkPubkey,
    String? p2pkSigFlags,
    String? p2pkNSig,
    String? p2pkLockTime,
    String? p2pkRefund,
  ) {
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an amount',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // TODO: Create ecash token using Rust API
    print('Creating ecash token: $amount sats, memo: $memo, mint: $mintUrl');
    if (isP2PKEnabled) {
      print('P2PK enabled: pubkey=$p2pkPubkey, sigFlags=$p2pkSigFlags, nSig=$p2pkNSig, lockTime=$p2pkLockTime, refund=$p2pkRefund');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Creating ecash token for $amount sats from $mintUrl...',
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

 
  /// Show payment success message
  void _showPaymentSuccess(int mintedAmount) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment received! $mintedAmount sats minted to wallet',
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh wallet balance and transactions
    _refreshWalletData();
  }

  /// Show all transactions dialog
  void _showAllTransactionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF0D0D0D),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ALL TRANSACTIONS',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF00FF00)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 16),
                // Transaction list
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: 'Courier',
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(index);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show transaction detail dialog
  void _showTransactionDetailDialog(TransactionInfo tx) {
    final isReceived = tx.direction == 'incoming';
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestamp.toInt());
    final dateStr = '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            isReceived ? 'Lightning Invoice' : 'Ecash Payment',
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  _buildDetailRow('Amount', '${tx.amount} sats'),
                  const SizedBox(height: 12),
                  
                  // Direction
                  _buildDetailRow('Type', isReceived ? 'Receive' : 'Send'),
                  const SizedBox(height: 12),
                  
                  // Date
                  _buildDetailRow('Date', dateStr),
                  const SizedBox(height: 12),
                  
                  // Transaction ID
                  _buildDetailRow('Transaction ID', tx.id, isMonospace: true),
                  const SizedBox(height: 12),
                  
                  // Memo (if exists)
                  if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                    _buildDetailRow('Memo', tx.memo!),
                    const SizedBox(height: 12),
                  ],
                  
                  // Status
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF00FF00)),
                        ),
                        child: const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build detail row for transaction details
  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontFamily: 'Courier',
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: TextStyle(
            color: const Color(0xFF00FF00),
            fontFamily: isMonospace ? 'Courier' : null,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Refresh wallet data after minting
  Future<void> _refreshWalletData() async {
    try {
      // Use new bulk methods to get all data at once
      final allBalances = await getAllBalances();
      final allTransactions = await getAllTransactions();
      
      // Calculate total balance from all mints
      BigInt totalBalance = BigInt.zero;
      for (final balance in allBalances.values) {
        totalBalance += balance;
      }
      
      // Sort transactions by timestamp (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Create aggregated wallet info
      final aggregatedWalletInfo = WalletInfo(
        mintUrl: 'Multiple Mints',
        unit: 'sat',
        balance: totalBalance,
        activeKeysetId: 'aggregated',
      );
      
      // Update UI
      setState(() {
        _walletInfo = aggregatedWalletInfo;
        _transactions = allTransactions;
      });
      
      print('Wallet data refreshed - Total Balance: ${totalBalance}, Total Transactions: ${allTransactions.length}');
    } catch (e) {
      print('Failed to refresh wallet data: $e');
    }
  }

  void _payLightningInvoice(String invoice) async {
    if (invoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a lightning invoice',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paying lightning invoice...',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Get the first mint URL
      final mints = await listMints();
      if (mints.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No mints available. Please add a mint first.',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: Color(0xFF1A1A1A),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Extract mint URL from format "mint_url:unit"
      final mintString = mints.first;
      final lastColonIndex = mintString.lastIndexOf(':');
      final mintUrl = lastColonIndex != -1 
          ? mintString.substring(0, lastColonIndex)
          : mintString;

      // Pay lightning invoice using new API
      print('Dart: Paying lightning invoice: $invoice');
      final paymentStatus = await payInvoiceForWallet(
        mintUrl: mintUrl,
        bolt11Invoice: invoice,
        maxFeeSats: BigInt.from(100), // Max fee of 100 sats
      );
      print('Dart: Payment status: $paymentStatus');

      Navigator.of(context).pop(); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lightning payment completed! Status: $paymentStatus',
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh wallet balance and transactions
      _refreshWalletData();
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pay lightning invoice: $e',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Stop specific monitoring when page is disposed, but keep global monitoring running
    WalletService.stopMintQuoteMonitoring();
    WalletService.stopMeltQuoteMonitoring();
    // Don't stop global monitoring - it should continue running in the background
    super.dispose();
  }
}
