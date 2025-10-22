import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'mints_page.dart';

/// Main settings page with navigation to sub-settings
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            context,
            title: 'Mints',
            subtitle: 'Manage mint servers',
            icon: Icons.account_balance_wallet,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MintsPage()),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Security',
            subtitle: 'Seed phrase and restore options',
            icon: Icons.security,
            onTap: () => _showSecurityDialog(context),
          ),
          // Temporarily disabled - Network/Tor settings
          // _buildSettingsCard(
          //   context,
          //   title: 'Network',
          //   subtitle: 'Tor settings',
          //   icon: Icons.network_check,
          //   onTap: () => _showNetworkDialog(context),
          // ),
          _buildSettingsCard(
            context,
            title: 'About',
            subtitle: 'Application information',
            icon: Icons.info,
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF00FF00), width: 1),
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
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF666666), size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'About',
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
                'PurrWallet',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Version: 1.0.0',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A Cashu-based e-cash wallet for secure and private transactions.',
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

  void _showSecurityDialog(BuildContext context) {
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
                  _showSeedPhraseDialog(context);
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

  void _showSeedPhraseDialog(BuildContext context) {
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
                    '⚠️ Keep this seed phrase safe!\nWrite it down and store it securely.',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
        // Convert hex to mnemonic using Rust function
        try {
          final mnemonic = await seedHexToMnemonic(seedHex: seedHex);
          return mnemonic;
        } catch (e) {
          return 'Error converting seed to mnemonic: $e\nHex: ${seedHex.substring(0, 16)}...';
        }
      } else {
        return 'No seed phrase found';
      }
    } catch (e) {
      return 'Error loading seed: $e';
    }
  }

  void _showNetworkDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load current settings from SharedPreferences
    String torMode = prefs.getString('torMode') ?? 'OnionOnly';
    
    // If torMode is Always, enable Tor; otherwise disable it (OnionOnly is default)
    bool isTorEnabled = torMode == 'Always';

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
                    Text(
                      isTorEnabled
                        ? 'Use Tor for all network requests'
                        : 'Only use Tor for .onion addresses (default)',
                      style: const TextStyle(
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Set torMode based on checkbox: unchecked = OnionOnly, checked = Always
                    final torMode = isTorEnabled ? 'Always' : 'OnionOnly';
                    _saveNetworkSettings(context, torMode);
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

  void _saveNetworkSettings(BuildContext context, String torMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save Tor mode (OnionOnly or Always) to SharedPreferences
      await prefs.setString('torMode', torMode);
      

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save network settings: $e',
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