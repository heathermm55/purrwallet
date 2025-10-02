import 'package:flutter/material.dart';
import 'create_account_page.dart';
import 'login_page.dart';

/// Login home page - IRC style
class LoginHomePage extends StatefulWidget {
  const LoginHomePage({super.key});

  @override
  State<LoginHomePage> createState() => _LoginHomePageState();
}

class _LoginHomePageState extends State<LoginHomePage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  final List<Map<String, String>> _features = [
    {
      'title': 'PURRWALLET',
      'subtitle': 'Nostr Cashu Wallet',
      'description': 'Decentralized Bitcoin Lightning Wallet',
    },
    {
      'title': 'SECURE',
      'subtitle': 'End-to-End Encryption',
      'description': 'Your keys, your coins, your privacy',
    },
    {
      'title': 'FAST',
      'subtitle': 'Lightning Network',
      'description': 'Instant Bitcoin transactions',
    },
    {
      'title': 'SOCIAL',
      'subtitle': 'Nostr Protocol',
      'description': 'Decentralized social payments',
    },
    {
      'title': 'OPEN',
      'subtitle': 'Open Source',
      'description': 'Transparent and auditable code',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

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
    _animationController.dispose();
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
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated ASCII art border
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFF00FF00).withOpacity(
                                    0.5 + 0.5 * _animationController.value,
                                  ),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    feature['title']!,
                                    style: TextStyle(
                                      color: Color(0xFF00FF00).withOpacity(
                                        0.7 + 0.3 * _animationController.value,
                                      ),
                                      fontFamily: 'Courier',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feature['subtitle']!,
                                    style: TextStyle(
                                      color: Color(0xFF00FF00).withOpacity(
                                        0.5 + 0.3 * _animationController.value,
                                      ),
                                      fontFamily: 'Courier',
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feature['description']!,
                                    style: TextStyle(
                                      color: Color(0xFF666666).withOpacity(
                                        0.7 + 0.3 * _animationController.value,
                                      ),
                                      fontFamily: 'Courier',
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                      builder: (context) => const CreateAccountPage(),
                    ),
                  );
                },
                child: const Text(
                  'CREATE ACCOUNT',
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
