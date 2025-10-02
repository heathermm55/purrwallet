import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/nostr.dart';
import 'package:rust_plugin/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Rust library
  await RustLib.init();
  
  runApp(const PurrWalletApp());
}

class PurrWalletApp extends StatelessWidget {
  const PurrWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PurrWallet',
      theme: ThemeData(
        // IRC-style theme - dark background with green text
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF00), // Green
          secondary: Color(0xFF00CC00),
          surface: Color(0xFF1A1A1A), // Dark gray background
          background: Color(0xFF000000), // Black background
          onPrimary: Color(0xFF000000),
          onSecondary: Color(0xFF000000),
          onSurface: Color(0xFF00FF00),
          onBackground: Color(0xFF00FF00),
        ),
        fontFamily: 'Courier', // Monospace font for IRC style
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
          titleLarge: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Color(0xFF00FF00),
          titleTextStyle: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: const Color(0xFF00FF00),
            side: const BorderSide(color: Color(0xFF00FF00)),
            textStyle: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00FF00),
            textStyle: const TextStyle(
              fontFamily: 'Courier',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00FF00)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00FF00)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00FF00), width: 2),
          ),
          labelStyle: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
          hintStyle: TextStyle(
            color: Color(0xFF666666),
            fontFamily: 'Courier',
          ),
        ),
      ),
      home: const LoginHomePage(),
    );
  }
}

/// Login home page - IRC style
class LoginHomePage extends StatelessWidget {
  const LoginHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IRC-style ASCII art title
            const Text(
              '''
╔══════════════════════════════════════╗
║            PURRWALLET                 ║
║        Nostr Cashu Wallet             ║
╚══════════════════════════════════════╝
              ''',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),
            
            // Create account button
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAccountPage(),
                    ),
                  );
                },
                child: const Text(
                  '[ CREATE ACCOUNT ]',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Already have account button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: const Text(
                'Already have account? Click here',
                style: TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // IRC-style welcome message
            const Text(
              'Welcome to the decentralized future!',
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create account page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _isGenerating = false;
  NostrKeys? _generatedKeys;

  Future<void> _generateAccount() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Call Rust function to generate Nostr keys
      final keys = generateKeys();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Padding(
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
                    SelectableText(
                      _generatedKeys!.publicKey,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF00FF00),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    const Text('Private Key (nsec):'),
                    const SizedBox(height: 5),
                    SelectableText(
                      _generatedKeys!.privateKey,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Color(0xFF00FF00),
                      ),
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
                        '⚠️  IMPORTANT: Save your private key securely!\n'
                        '   This is the only way to access your account.\n'
                        '   Never share it with anyone.',
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
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to main app interface
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainAppPage(),
                      ),
                    );
                  },
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
            
            const SizedBox(height: 30),
            
            // Back button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _privateKeyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final privateKey = _privateKeyController.text.trim();
    
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
      // Validate private key and get public key
      final publicKey = getPublicKeyFromPrivate(privateKey: privateKey);
      
      // TODO: Save login state
      
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
            content: Text('Invalid private key: $e'),
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
                labelText: 'Private Key (nsec)',
                hintText: 'nsec1...',
                helperText: 'Enter your Nostr private key to login',
              ),
              obscureText: true,
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

/// Main app page (placeholder)
class MainAppPage extends StatelessWidget {
  const MainAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PURRWALLET'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: const Center(
        child: Text(
          'Welcome to PurrWallet!\n\nThis is the main app interface.\nMore features coming soon...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}