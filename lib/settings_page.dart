import 'package:flutter/material.dart';
import 'accounts/services/auth_service.dart';
import 'settings/mints_page.dart';
import 'settings/security_page.dart';
import 'settings/network_page.dart';

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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecurityPage()),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'Network',
            subtitle: 'Proxy and Tor settings',
            icon: Icons.network_check,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NetworkPage()),
              );
            },
          ),
          _buildSettingsCard(
            context,
            title: 'About',
            subtitle: 'Application information',
            icon: Icons.info,
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingsCard(
            context,
            title: 'Account',
            subtitle: 'Account info and logout',
            icon: Icons.person,
            onTap: () => _showAccountMenuDialog(context),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFFFF6B6B)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
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

  void _showAccountMenuDialog(BuildContext context) {
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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: Color(0xFF00FF00)),
                title: Text(
                  'Account Info',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
                subtitle: Text(
                  'View account details',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
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

  void _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: $e',
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
}