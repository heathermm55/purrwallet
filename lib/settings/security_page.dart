import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Security settings page - Seed phrase and restore options
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

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
          'Security',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF00)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSecurityCard(
            context,
            title: 'View Seed Phrase',
            subtitle: 'Display wallet seed phrase',
            icon: Icons.vpn_key,
            onTap: () => _showSeedPhraseDialog(context),
          ),
          _buildSecurityCard(
            context,
            title: 'Restore Wallet',
            subtitle: 'Restore from backup',
            icon: Icons.restore,
            onTap: () => _showRestoreDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
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
                style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier', fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final TextEditingController seedController = TextEditingController();

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
                controller: seedController,
                style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Paste your seed phrase here...',
                  hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF00))),
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
                style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement restore wallet functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Restore functionality coming soon',
                      style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    ),
                    backgroundColor: Color(0xFF1A1A1A),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Restore',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
          ],
        );
      },
    );
  }
}

