import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

import '../services/wallet_service.dart';

/// Import wallet page - Import wallet using seed phrase
class ImportWalletPage extends StatefulWidget {
  const ImportWalletPage({super.key});

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isImporting = false;
  bool _isValidMnemonic = false;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_validateMnemonic);
  }

  void _validateMnemonic() {
    final text = _mnemonicController.text.trim();
    final words = text.split(RegExp(r'\s+'));
    
    // Check if we have exactly 12 words and all are non-empty
    final isValid = words.length == 12 && words.every((word) => word.isNotEmpty);
    
    if (_isValidMnemonic != isValid) {
      setState(() {
        _isValidMnemonic = isValid;
      });
    }
  }

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
      final isValid = await validateMnemonicPhrase(mnemonicPhrase: mnemonicPhrase);
      if (!isValid) {
        setState(() {
          _isImporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Invalid mnemonic phrase. Please check your words and try again.',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Convert mnemonic to seed hex
      final seedHex = await mnemonicToSeedHex(mnemonicPhrase: mnemonicPhrase);
      
      // Save seed hex to secure storage
      await _secureStorage.write(key: _seedKey, value: seedHex);

      // Initialize MultiMintWallet with imported seed
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      await initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);
      await WalletService.restoreMintsFromBackup();

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
            const SizedBox(height: 16),
            
            // Main Title
            const Text(
              'Import Wallet',
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
              'Enter your 12-word seed phrase to restore your wallet.',
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Seed Phrase Input
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
                  const Text(
                    'Seed Phrase',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mnemonicController,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter your 12-word mnemonic phrase here...',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                      ),
                      border: InputBorder.none,
                      helperText: '12-word mnemonic phrase separated by spaces',
                      helperStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Import button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (!_isImporting && _isValidMnemonic) ? _importWallet : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isImporting 
                      ? const Color(0xFF333333)
                      : _isValidMnemonic 
                          ? const Color(0xFF00FF00) 
                          : const Color(0xFF333333),
                  foregroundColor: _isImporting || !_isValidMnemonic
                      ? Colors.grey 
                      : Colors.black,
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
            
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }
}
