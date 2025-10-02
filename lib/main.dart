import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/frb_generated.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'accounts/login_home_page.dart';
import 'main_app_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Rust library
  await RustLib.init();
  
  // Initialize database
  await DatabaseService.init();
  
  // Initialize auth service
  await AuthService.init();
  
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
      home: const AppStartPage(),
    );
  }
}

/// App start page that checks for auto-login
class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Check if there's an active user
      final activeUser = await DatabaseService.getActiveUser();
      
      if (activeUser != null) {
        // Set as current user in auth service
        AuthService.setCurrentUser(activeUser);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainAppPage(),
            ),
          );
        }
      } else {
        // No active user, go to login home
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
      // If there's an error, go to login home
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
            const Text(
              'Loading...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
