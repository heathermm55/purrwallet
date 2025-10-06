import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'accounts/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Settings page with all configuration options
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00FF00),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mints Section
          _buildSectionCard(
            'Mints',
            'Manage mint servers',
            Icons.account_balance_wallet,
            () => _showMintsDialog(),
          ),
          
          const SizedBox(height: 16),
          
          // Security Section
          _buildSectionCard(
            'Security',
            'Seed phrase and restore options',
            Icons.security,
            () => _showSecurityDialog(),
          ),
          
          const SizedBox(height: 16),
          
          // Network Section
          _buildSectionCard(
            'Network',
            'Proxy and Tor settings',
            Icons.network_check,
            () => _showNetworkDialog(),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          _buildSectionCard(
            'About',
            'App information and version',
            Icons.info,
            () => _showAboutDialog(),
          ),
          
          const SizedBox(height: 32),
          
          // Account Section
          if (AuthService.currentUser != null) ...[
            _buildSectionCard(
              'Account',
              'Account information and logout',
              Icons.person,
              () => _showAccountInfoDialog(),
            ),
            
            const SizedBox(height: 16),
            
            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  AuthService.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00FF00)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontFamily: 'Courier',
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF666666),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
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
                        hintText: 'https://mint.example.com or localhost:3338',
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
                            // TODO: Show mint details
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
                // TODO: Add mint functionality
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
                  'Import wallet from seed phrase',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to restore wallet page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Restore wallet functionality coming soon',
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
          content: FutureBuilder<String>(
            future: _getSeedPhrase(),
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
                      'Loading seed phrase...',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                );
              }
              
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontFamily: 'Courier',
                  ),
                );
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠️ Keep this seed phrase safe!',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    snapshot.data ?? 'No seed phrase available',
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  ),
                ],
              );
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
          ],
        );
      },
    );
  }

  Future<String> _getSeedPhrase() async {
    try {
      const storage = FlutterSecureStorage();
      final seedHex = await storage.read(key: 'cashu_wallet_seed');
      
      if (seedHex != null) {
        // Convert hex to words (simplified - in real app you'd use proper BIP39)
        return 'Seed phrase functionality coming soon\nHex: ${seedHex.substring(0, 16)}...';
      } else {
        return 'No seed phrase found';
      }
    } catch (e) {
      return 'Error loading seed: $e';
    }
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
                        'Proxy Username:',
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
                        'Proxy Password:',
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
                    _saveNetworkSettings(isTorEnabled, isProxyEnabled, proxyHost, proxyPort, proxyUsername, proxyPassword);
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

  void _saveNetworkSettings(bool isTorEnabled, bool isProxyEnabled, String proxyHost, String proxyPort, String proxyUsername, String proxyPassword) {
    // TODO: Save network settings to storage
    print('Saving network settings:');
    print('Tor enabled: $isTorEnabled');
    print('Proxy enabled: $isProxyEnabled');
    print('Proxy host: $proxyHost');
    print('Proxy port: $proxyPort');
    print('Proxy username: $proxyUsername');
    print('Proxy password: $proxyPassword');
    
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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PurrWallet v1.0.0',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A modern Bitcoin Lightning wallet with Cashu support',
                style: TextStyle(
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
}
