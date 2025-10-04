import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Import wallet page - Import wallet using seed phrase
class ImportWalletPage extends StatefulWidget {
  const ImportWalletPage({super.key});

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController(text: 'PurrWallet User');
  bool _isImporting = false;
  bool _isShowingHexInput = false;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  void _importWallet() async {
    final mnemonicPhrase = _mnemonicController.text.trim();
    
    if (mnemonicPhrase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your mnemonic phrase',
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
      _isImporting = true;
    });

    try {
      // Validate mnemonic phrase first
      final isValid = validateMnemonicPhrase(mnemonicPhrase);
      if (!isValid) {
        setState(() {
          _isImporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid mnemonic phrase. Please check your words and try again.',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 3),
        ),
        );
        return;
      }

      // Convert mnemonic to seed hex
      final seedHex = mnemonicToSeedHex(mnemonicPhrase);
      
      // Save seed hex to secure storage
      await _secureStorage.write(key: _seedKey, value: seedHex);

      // Initialize MultiMintWallet with imported seed
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);
      print('MultiMintWallet init result: $initResult');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to import wallet: $e',
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
          'IMPORT WALLET',
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
            
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF00FF00)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Instructions',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Enter your 64-character hex seed phrase',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '2. Optionally set a display name',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '3. Tap Import to restore your wallet',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Display Name
            const Text(
              'Display Name (optional):',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
              decoration: const InputDecoration(
                hintText: 'Enter display name',
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
            
            const SizedBox(height: 20),
            
            // Seed Phrase
            const Text(
              'Seed Phrase (64 hex chars):',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seedController,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your 64-character hex seed phrase here...',
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
                helperText: '64-character hexadecimal string (0-9, a-f)',
                helperStyle: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Import button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                ),
                child: _isImporting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      )
                    : const Text(
                        'IMPORT WALLET',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Security Notice
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
                    'SECURITY NOTICE',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Never enter your seed phrase on untrusted devices.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Make sure you are using the official PurrWallet app.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _seedController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
}
