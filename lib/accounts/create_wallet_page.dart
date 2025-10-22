import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart:math';

/// Create wallet page - Generate seed phrase and create wallet
class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  String? _generatedMnemonic;
  String? _generatedSeedHex;
  String? _generatedNpub;
  bool _isGenerating = false;
  bool _isCreating = false;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  @override
  void initState() {
    super.initState();
    _generateWallet();
  }

  void _generateWallet() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate BIP39 mnemonic phrase (24 words)
      final mnemonic = generateMnemonicPhrase(24);
      
      // Convert mnemonic to seed hex
      final seedHex = mnemonicToSeedHex(mnemonic);
      
      // Generate Nostr keys for wallet identification using the seed
      final keys = generateKeysWithBech32();
      
      setState(() {
        _generatedMnemonic = mnemonic;
        _generatedSeedHex = seedHex;
        _generatedNpub = keys.npub;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate wallet: $e',
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Copied to clipboard',
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

  Future<void> _createWallet() async {
    if (_generatedSeedHex == null || _generatedNpub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wallet not generated yet',
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

    setState(() {
      _isCreating = true;
    });

    try {
      // Save seed hex to secure storage
      await _secureStorage.write(key: _seedKey, value: _generatedSeedHex!);

      // Initialize MultiMintWallet
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: _generatedSeedHex!);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create wallet: $e',
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'CREATE WALLET',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFF00FF00)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Wallet Info
            const Text(
              'Wallet Information',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF00FF00)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ IMPORTANT: Save your seed phrase',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Public Key (npub):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_generatedNpub != null)
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedNpub!,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_generatedNpub!),
                          icon: const Icon(
                            Icons.content_copy,
                            color: Color(0xFF00FF00),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  
                  if (_generatedMnemonic != null) ...[
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Seed Phrase (24 words):',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedMnemonic!,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_generatedMnemonic!),
                          icon: const Icon(
                            Icons.content_copy,
                            color: Color(0xFF00FF00),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Seed Hex (64 chars):',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedSeedHex!,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_generatedSeedHex!),
                          icon: const Icon(
                            Icons.content_copy,
                            color: Color(0xFF00FF00),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Security Warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A1A),
                border: Border.all(color: Color(0xFFFF6B6B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY WARNING',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Keep your seed phrase secure and private',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '• Never share your seed phrase with anyone',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '• Store it in a safe place offline',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '• Your funds can be restored with this seed phrase',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action buttons
            if (_isGenerating)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
              )
            else if (_generatedSeedHex != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        )
                      : const Text(
                          'CONTINUE TO WALLET',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
