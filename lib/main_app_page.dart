import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:convert';

/// Main app page - Wallet interface
class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  // Cashu Wallet state
  WalletInfo? _walletInfo;
  List<CashuProof> _proofs = [];
  List<TransactionInfo> _transactions = [];
  bool _isWalletInitialized = false;
  String _walletStatus = 'Initializing...';
  
  // Secure storage for seed
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  /// Generate a new 32-byte seed as hex string
  String _generateSeedHex() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get or create seed from secure storage
  Future<String> _getOrCreateSeed() async {
    try {
      // Try to get existing seed
      final existingSeed = await _secureStorage.read(key: _seedKey);
      if (existingSeed != null && existingSeed.length == 64) {
        print('Using existing seed from secure storage');
        return existingSeed;
      }
    } catch (e) {
      print('Error reading seed from storage: $e');
    }

    // Generate new seed if none exists or invalid
    final newSeed = _generateSeedHex();
    try {
      await _secureStorage.write(key: _seedKey, value: newSeed);
      print('Generated and stored new seed');
    } catch (e) {
      print('Error storing seed: $e');
    }
    
    return newSeed;
  }

  Future<void> _initializeWallet() async {
    try {
      setState(() {
        _walletStatus = 'Creating wallet...';
      });

      // Get application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final databaseDir = documentsDir.path;

      // Get or create seed from secure storage
      final seedHex = await _getOrCreateSeed();
      print('Using seed: ${seedHex.substring(0, 8)}...');

      // Initialize MultiMintWallet with seed
      final initResult = initMultiMintWallet(databaseDir: databaseDir, seedHex: seedHex);
      print('MultiMintWallet init result: $initResult');

      // Load existing wallets from database
      final loadResult = loadExistingWallets();
      print('Load existing wallets result: $loadResult');

      // Add default mint if no wallets were loaded
      const mintUrl = 'https://8333.space'; // Default local mint
      const unit = 'sat';
      
      final addMintResult = addMint(mintUrl: mintUrl, unit: unit);
      print('Add mint result: $addMintResult');

      // List all mints
      final mints = listMints();
      print('Available mints: $mints');

      // Try to get wallet info, but handle errors gracefully
      WalletInfo? walletInfo;
      List<CashuProof> proofs = [];
      List<TransactionInfo> transactions = [];
      
      try {
        walletInfo = getWalletInfo(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
        print('Wallet info: $walletInfo');
      } catch (e) {
        print('Failed to get wallet info: $e');
        // Create a default wallet info
        walletInfo = WalletInfo(
          mintUrl: mintUrl,
          unit: unit,
          balance: BigInt.zero,
          activeKeysetId: 'default',
        );
      }

      try {
        proofs = getWalletProofs(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
        print('Proofs: ${proofs.length}');
      } catch (e) {
        print('Failed to get proofs: $e');
        proofs = [];
      }

      try {
        transactions = getWalletTransactions(mintUrl: mintUrl, unit: unit, databaseDir: databaseDir);
        print('Transactions: ${transactions.length}');
      } catch (e) {
        print('Failed to get transactions: $e');
        transactions = [];
      }

      setState(() {
        _walletInfo = walletInfo;
        _proofs = proofs;
        _transactions = transactions;
        _isWalletInitialized = true;
        _walletStatus = 'Wallet ready';
      });
    } catch (e) {
      setState(() {
        _walletStatus = 'Error: $e';
        _isWalletInitialized = false;
      });
      print('Wallet initialization error: $e');
    }
  }

  String _formatBalance(String balance) {
    try {
      final amount = int.parse(balance);
      if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}k';
      }
      return amount.toString();
    } catch (e) {
      return '0';
    }
  }

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
                    final balance = _walletInfo?.balance.toString() ?? '0';
                    final balanceFormatted = _formatBalance(balance);
                    return _buildWalletCard(
                      'Local Wallet',
                      '$balanceFormatted sats',
                      '\$0.00', // TODO: Add USD conversion
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
                childCount: _transactions.length, // Match the number of transactions in the array
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
    if (index >= _transactions.length) {
      return const SizedBox.shrink();
    }
    
    final tx = _transactions[index];
    final isReceived = tx.direction == 'in';
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestamp.toInt());
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
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
              color: (isReceived ? Colors.green : Colors.red).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceived ? Icons.arrow_upward : Icons.arrow_downward,
              color: isReceived ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.memo ?? (isReceived ? 'Received' : 'Sent'),
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cashu Transaction',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                Text(
                  timeStr,
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
                '${isReceived ? '+' : '-'}${tx.amount} sats',
                style: TextStyle(
                  color: isReceived ? Colors.green : Colors.red,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '~\$0.00',
                style: TextStyle(
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

  Widget _buildBottomNavButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}
