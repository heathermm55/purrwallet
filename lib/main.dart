import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/frb_generated.dart';
import 'wallet/pages/wallet_start_page.dart';
import 'main_app_page.dart';
import 'main_app_page_adaptive.dart';

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
      home: const WalletStartPage(),
      routes: {
        '/main': (context) => const MainAppPage(),
        '/main_adaptive': (context) => const MainAppPageAdaptive(),
      },
    );
  }
}

