import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';
import 'auth_service.dart';
import '../main_app_page.dart';

/// Create account page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _isGenerating = false;
  NostrKeysWithBech32? _generatedKeys;
  final _displayNameController = TextEditingController();

  Future<void> _generateAccount() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Call Rust function to generate Nostr keys with bech32 format
      final keys = generateKeysWithBech32();
      setState(() {
        _generatedKeys = keys;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAccount() async {
    if (_generatedKeys == null) return;
    
    final displayName = _displayNameController.text.trim();

    try {
      // Create user account with auto-generated password
      final user = await AuthService.loginWithPrivateKey(
        privateKey: _generatedKeys!.privateKey,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: const Color(0xFF00FF00),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Generate New Nostr Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isGenerating) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                    ),
                    SizedBox(height: 20),
                    Text('Generating secure keys...'),
                  ],
                ),
              ),
            ] else if (_generatedKeys != null) ...[
              // Display generated keys
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00FF00)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT CREATED SUCCESSFULLY!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    const Text('Public Key (npub):'),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedKeys!.npub,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: Color(0xFF00FF00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => _copyToClipboard(_generatedKeys!.npub, 'npub'),
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFF00FF00),
                            size: 20,
                          ),
                          tooltip: 'Copy npub',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    const Text('Private Key (nsec):'),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedKeys!.nsec,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: Color(0xFF00FF00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => _copyToClipboard(_generatedKeys!.nsec, 'nsec'),
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFF00FF00),
                            size: 20,
                          ),
                          tooltip: 'Copy nsec',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ IMPORTANT: Save your private key securely!\n'
                        'This is the only way to access your account.\n'
                        'Never share it with anyone.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Display name input
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
              
              // Save account and continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  child: const Text('CONTINUE TO WALLET'),
                ),
              ),
            ] else ...[
              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generateAccount,
                  child: const Text('GENERATE NEW ACCOUNT'),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
