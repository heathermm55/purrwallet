import 'package:flutter/material.dart';

/// Main app page - Wallet interface
class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'WALLET',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add wallet functionality
            },
            icon: const Icon(
              Icons.add,
              color: Color(0xFF00FF00),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Settings functionality
            },
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF00FF00),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Wallet Cards Section
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3, // Local Wallet, NIP60 Wallet, Add Wallet
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildWalletCard(
                      'Local Wallet 01',
                      '1,000 sats',
                      '\$0.37',
                      const LinearGradient(
                        colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                      ),
                      Icons.flash_on,
                    );
                  } else if (index == 1) {
                    return _buildWalletCard(
                      'NIP60 Wallet 01',
                      '1,000 sats',
                      '\$0.37',
                      const LinearGradient(
                        colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                      ),
                      Icons.flash_on,
                    );
                  } else {
                    return _buildAddWalletCard();
                  }
                },
              ),
            ),
          ),
          
          // Page indicators
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF333333),
                  ),
                );
              }),
            ),
          ),
          
          SliverToBoxAdapter(
            child: const SizedBox(height: 20),
          ),
          
          // Notification Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: const Color(0xFF00FF00)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFF00FF00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have 3 nuts zaps to Claim',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF00FF00),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: const SizedBox(height: 20),
          ),
          
          // Transaction History Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRANSACTION',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full transaction list
                    },
                    child: const Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: const SizedBox(height: 16),
          ),
          
          // Transaction List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTransactionItem(index),
                );
              },
              childCount: 5, // Match the number of transactions in the array
            ),
          ),
          
          // Add bottom padding to account for bottom navigation
          SliverToBoxAdapter(
            child: const SizedBox(height: 100),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(color: Color(0xFF333333)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavButton('Receive', Icons.keyboard_arrow_down),
            _buildBottomNavButton('Scan', Icons.qr_code_scanner),
            _buildBottomNavButton('Swap', Icons.swap_horiz),
            _buildBottomNavButton('Send', Icons.keyboard_arrow_up),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(String title, String sats, String usd, Gradient gradient, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Icon(
                icon,
                color: const Color(0xFF00FF00),
                size: 32,
              ),
            ],
          ),
          const Spacer(),
          Text(
            sats,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            usd,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddWalletCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF00)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add,
            color: Color(0xFF00FF00),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Add Wallet',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "It's free, and you can create as many as you like",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(int index) {
    final transactions = [
      {'type': 'Ecash', 'time': '1 hour ago', 'desc': 'Received from user', 'amount': '+1 sat', 'usd': '~\$0.00', 'icon': Icons.arrow_upward, 'color': Colors.green},
      {'type': 'Lightning', 'time': '2 hours ago', 'desc': 'Payment to merchant', 'amount': '-1 sat', 'usd': '~\$0.00', 'icon': Icons.arrow_downward, 'color': Colors.red},
      {'type': 'Lightning', 'time': '3 hours ago', 'desc': 'Pending payment', 'amount': '-1 sat', 'usd': '~\$0.00', 'icon': Icons.access_time, 'color': Colors.orange},
      {'type': 'Ecash', 'time': '1 day ago', 'desc': 'Received from user', 'amount': '+1 sat', 'usd': '~\$0.00', 'icon': Icons.arrow_upward, 'color': Colors.green},
      {'type': 'Lightning', 'time': '2 days ago', 'desc': 'Payment to merchant', 'amount': '-1 sat', 'usd': '~\$0.00', 'icon': Icons.arrow_downward, 'color': Colors.red},
    ];
    
    final tx = transactions[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (tx['color'] as Color).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx['icon'] as IconData,
              color: tx['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['type'] as String,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tx['desc'] as String,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                Text(
                  tx['time'] as String,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx['amount'] as String,
                style: TextStyle(
                  color: tx['color'] as Color,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                tx['usd'] as String,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavButton(String label, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: const Color(0xFF00FF00),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
