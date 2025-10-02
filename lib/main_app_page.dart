import 'package:flutter/material.dart';

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
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: const Center(
        child: Text(
          'Welcome to PurrWallet!\n\nThis is the main app interface.\nMore features coming soon...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
      ),
    );
  }
}
