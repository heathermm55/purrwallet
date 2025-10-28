import 'package:flutter/material.dart';
import '../wallet/pages/create_wallet_page.dart';
import '../wallet/pages/import_wallet_page.dart';

/// Login home page - IRC style
class LoginHomePage extends StatefulWidget {
  const LoginHomePage({super.key});

  @override
  State<LoginHomePage> createState() => _LoginHomePageState();
}

class _LoginHomePageState extends State<LoginHomePage> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'CROSS-PLATFORM',
      'subtitle': 'Ecash Wallet',
      'description': 'Available on all platforms',
      'icon': Icons.devices,
    },
    {
      'title': 'LOCAL/TOR',
      'subtitle': 'Mint Support',
      'description': 'Connect to local or Tor mints',
      'icon': Icons.network_wifi,
    },
    {
      'title': 'SECURE & POWERFUL',
      'subtitle': 'Lightning Speed',
      'description': 'Secure and powerful transactions',
      'icon': Icons.flash_on,
    },
    {
      'title': 'IRC STYLE',
      'subtitle': 'Retro Interface',
      'description': 'Classic terminal aesthetics',
      'icon': Icons.terminal,
    },
    {
      'title': 'OPEN SOURCE',
      'subtitle': 'Transparent Code',
      'description': 'Fully auditable and transparent',
      'icon': Icons.code,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto-scroll through features
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (_currentPage < _features.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Feature carousel
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Feature display with icon
                        Column(
                          children: [
                            // Icon
                            Icon(
                              feature['icon'] as IconData,
                              size: 48,
                              color: const Color(0xFF00FF00),
                            ),
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              feature['title']!,
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            Text(
                              feature['subtitle']!,
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Description
                            Text(
                              feature['description']!,
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF333333),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Create account button
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWalletPage(),
                    ),
                  );
                },
                child: const Text(
                  'CREATE WALLET',
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
                    builder: (context) => const ImportWalletPage(),
                  ),
                );
              },
              child: const Text(
                'Already have wallet? Import here',
                style: TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
