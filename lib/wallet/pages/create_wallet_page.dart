import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

import '../services/wallet_service.dart';

/// Create wallet page - Generate seed phrase and create wallet
class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  String? _generatedMnemonic;
  String? _generatedSeedHex;
  bool _isGenerating = false;
  bool _isCreating = false;
  bool _hasAgreed = false;
  bool _isSeedVisible = false;

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
      // Generate BIP39 mnemonic phrase (12 words)
      final mnemonic = await generateMnemonicPhrase(wordCount: 12);
      
      // Convert mnemonic to seed hex
      final seedHex = await mnemonicToSeedHex(mnemonicPhrase: mnemonic);
      
      setState(() {
        _generatedMnemonic = mnemonic;
        _generatedSeedHex = seedHex;
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
    if (_generatedSeedHex == null) {
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
      await WalletService.storeMnemonic(_generatedMnemonic!);

      // Initialize MultiMintWallet
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      await initMultiMintWallet(databaseDir: databaseDir, seedHex: _generatedSeedHex!);

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
            const SizedBox(height: 16),
            
            // Main Title
            const Text(
              'Your Seed Phrase',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Instruction text
            const Text(
              'Store your seed phrase in a password manager or on paper. If your device is lost, your seed phrase is the only way to recover funds.',
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Seed phrase box
            if (_generatedMnemonic != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF444444),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          const Text(
                            'Seed Phrase',
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSeedVisible = !_isSeedVisible;
                              });
                            },
                            icon: Icon(
                              _isSeedVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF00FF00),
                              size: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(_generatedMnemonic!),
                            icon: const Icon(
                              Icons.content_copy,
                              color: Color(0xFF00FF00),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _isSeedVisible ? _generatedMnemonic! : '*** *** *** *** *** *** *** *** *** *** *** ***',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontFamily: 'Courier',
                          fontSize: 14,
                          height: 1.3,
                        ),
                        textAlign: _isSeedVisible ? TextAlign.left : TextAlign.center,
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Confirmation checkbox
            if (_generatedMnemonic != null)
              Row(
                children: [
                  Checkbox(
                    value: _hasAgreed,
                    onChanged: (value) {
                      setState(() {
                        _hasAgreed = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF00FF00),
                    checkColor: Colors.black,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _hasAgreed = !_hasAgreed;
                        });
                      },
                      child: const Text(
                        'I have written it down',
                        style: TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
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
                  onPressed: (_isCreating || !_hasAgreed) ? null : _createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasAgreed 
                        ? const Color(0xFF00FF00) 
                        : const Color(0xFF333333),
                    foregroundColor: _hasAgreed 
                        ? Colors.black 
                        : Colors.grey,
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
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
