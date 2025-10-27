import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../accounts/login_home_page.dart';
import '../../main_app_page.dart';

/// Wallet start page that checks for existing wallet and initializes it
class WalletStartPage extends StatefulWidget {
  const WalletStartPage({super.key});

  @override
  State<WalletStartPage> createState() => _WalletStartPageState();
}

class _WalletStartPageState extends State<WalletStartPage> {
  String _status = 'Initializing wallet...';

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;
      
      // Check if wallet database exists
      final walletExistsFile = File('$databaseDir/multi_mint_wallet.db');
      final walletExists = await walletExistsFile.exists();
      
      final fileExists = walletExistsFile.existsSync();
      
      if (walletExists) {
        setState(() {
          _status = 'Found existing wallet, loading...';
        });

        // Check if we have a stored seed
        const storage = FlutterSecureStorage();
        final seedHex = await storage.read(key: 'cashu_wallet_seed');
        
        if (seedHex != null) {
          // Initialize MultiMintWallet with existing seed
          final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);

          // Mints are now empty by default - users can add their own mints

          setState(() {
            _status = 'Wallet loaded successfully';
          });

          if (mounted) {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainAppPage(),
              ),
            );
          }
        } else {
          // Database exists but no seed in storage, go to login home
          setState(() {
            _status = 'Database exists but config missing, please reconfigure';
          });
          
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginHomePage(),
              ),
            );
          }
        }
      } else {
        // No database exists, go to login home to let user choose
        setState(() {
          _status = 'First time setup, please choose to create or import wallet';
        });
        
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginHomePage(),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Wallet initialization failed: $e';
      });
      
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginHomePage(),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo image
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
            ),
            const SizedBox(height: 20),
            const Text(
              'PurrWallet',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
