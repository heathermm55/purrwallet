import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rust_plugin/src/rust/api/cashu.dart';

/// Security settings page - Seed phrase and Tor options
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';
  static const String _torPrefKey = 'cashu_tor_enabled';

  bool _torEnabled = true;
  bool _torLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTorSetting();
  }

  Future<void> _loadTorSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getBool(_torPrefKey);
      setState(() {
        _torEnabled = storedValue ?? true;
        _torLoading = false;
      });
    } catch (_) {
      setState(() {
        _torEnabled = true;
        _torLoading = false;
      });
    }
  }

  Future<void> _toggleTor(bool value) async {
    setState(() {
      _torEnabled = value;
      _torLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_torPrefKey, value);
      await setTorConfig(policy: value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Tor enabled' : 'Tor disabled',
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
    } catch (e) {
      setState(() {
        _torEnabled = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update Tor: $e',
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
    } finally {
      if (mounted) {
        setState(() {
          _torLoading = false;
        });
      }
    }
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
          _buildTorCard(),
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

  Widget _buildTorCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF00FF00), width: 1),
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF00FF00),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF333333),
        secondary: const Icon(Icons.shield, color: Color(0xFF00FF00)),
        title: const Text(
          'Use Tor when available',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Automatically route .onion traffic via Tor',
          style: TextStyle(
            color: Color(0xFF666666),
            fontFamily: 'Courier',
            fontSize: 12,
          ),
        ),
        value: _torEnabled,
        onChanged: _torLoading ? null : _toggleTor,
      ),
    );
  }
}

