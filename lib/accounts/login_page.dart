import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';
import 'auth_service.dart';
import '../main_app_page.dart';

/// Login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _privateKeyController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final privateKey = _privateKeyController.text.trim();
    final displayName = _displayNameController.text.trim();
    
    if (privateKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your private key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Login with private key (password auto-generated)
      final user = await AuthService.loginWithPrivateKey(
        privateKey: privateKey,
        displayName: displayName.isNotEmpty ? displayName : null,
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainAppPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNostrSignerOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'SELECT NOSTRSIGNER',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSignerOption('Amber', 'Hardware wallet'),
              const SizedBox(height: 12),
              _buildSignerOption('Aegis', 'Mobile app'),
              const SizedBox(height: 12),
              _buildSignerOption('Nowser', 'Desktop app'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
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

  Widget _buildSignerOption(String name, String description) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _connectToSigner(name);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FF00)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF00FF00),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToSigner(String signerName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual signer connection logic
      // This would typically involve:
      // 1. Scanning QR code or connecting via NFC
      // 2. Requesting public key from the signer
      // 3. Verifying connection
      
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainAppPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $signerName: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LOGIN'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Your Private Key',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Private Key (nsec or hex)',
                hintText: 'nsec1... or hex format',
                helperText: 'Enter your Nostr private key (nsec or hex) to login',
              ),
              obscureText: true,
              maxLines: 1,
            ),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name (Optional)',
                hintText: 'Enter your display name',
                helperText: 'Leave empty to use auto-generated name',
              ),
              maxLines: 1,
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                      )
                    : const Text('LOGIN'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Divider
            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFF333333))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFF333333))),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // NostrSigner login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showNostrSignerOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: const Color(0xFF00FF00),
                  side: const BorderSide(color: Color(0xFF00FF00)),
                  textStyle: const TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('LOGIN WITH NOSTRSIGNER'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
