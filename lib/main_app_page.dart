import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:math';
import 'settings/main_settings_page.dart';
import 'wallet/services/wallet_service.dart';
import 'wallet/pages/transactions_page.dart';
import 'wallet/pages/qr_scanner_page.dart';
import 'wallet/widgets/transaction_item.dart';
import 'wallet/dialogs/receive_options_dialog.dart';
import 'wallet/dialogs/send_options_dialog.dart';
import 'wallet/dialogs/ecash_receive_dialog.dart';
import 'wallet/dialogs/ecash_send_dialog.dart';
import 'wallet/dialogs/lightning_receive_dialog.dart';
import 'wallet/dialogs/lightning_send_dialog.dart';
import 'wallet/dialogs/invoice_display_dialog.dart';
import 'wallet/dialogs/ecash_token_dialog.dart';
import 'wallet/dialogs/manual_input_dialog.dart';

/// Main app page - Wallet interface
class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  // Cashu Wallet state
  WalletInfo? _walletInfo;
  List<TransactionInfo> _transactions = [];

  // Secure storage for seed
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _seedKey = 'cashu_wallet_seed';

  @override
  void initState() {
    super.initState();
    _initializeWallet();
    _setupUICallbacks();
  }

  /// Setup UI callbacks for monitoring updates
  void _setupUICallbacks() {
    // Set up callback for UI updates
    WalletService.onMintedAmountReceived = (Map<String, String> result) {
      if (mounted) {
        final totalMinted = int.parse(result['total_minted'] ?? '0');
        if (totalMinted > 0) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment received! $totalMinted sats minted to wallet',
                style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              duration: const Duration(seconds: 3),
            ),
          );

          // Refresh wallet data
          _refreshWalletData();
        }
      }
    };

    // Set up callback for melt quote updates
    WalletService.onMeltedAmountReceived = (Map<String, String> result) {
      if (mounted) {
        final completedCount = int.parse(result['completed_count'] ?? '0');
        if (completedCount > 0) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment sent! $completedCount melt quotes completed',
                style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              duration: const Duration(seconds: 3),
            ),
          );

          // Refresh wallet data
          _refreshWalletData();
        }
      }
    };

    WalletService.onWalletUpdated = () {
      if (mounted) {
        _refreshWalletData();
      }
    };
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
        return existingSeed;
      }
    } catch (e) {
      // Error reading seed from storage
    }

    // Generate new seed if none exists or invalid
    final newSeed = _generateSeedHex();
    try {
      await _secureStorage.write(key: _seedKey, value: newSeed);
    } catch (e) {
      // Error storing seed
    }

    return newSeed;
  }

  Future<void> _initializeWallet() async {
    try {
      // Get or create seed from secure storage
      final seedHex = await _getOrCreateSeed();

      // Initialize wallet using WalletService (this will automatically start monitoring)
      await WalletService.initializeWallet(seedHex);

      // Load wallet data if mints are available
      await _refreshWalletData();
    } catch (e) {
      // Wallet initialization error
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
        title: Row(
          children: [
            // Logo image in AppBar
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
            ),
            // const SizedBox(width: 12),
            const Text(
              'PURRWALLET',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings, color: Color(0xFF00FF00)),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Wallet Cards Section
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: _buildWalletCard(
                    'Local Wallet',
                    _walletInfo != null
                        ? '${_formatBalance(_walletInfo!.balance.toString())} sats'
                        : '0 sats',
                    null, // No USD display
                    const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)]),
                    Icons.flash_on,
                  ),
                ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsPage(
                                transactions: _transactions,
                                onRefresh: (_) => _refreshWalletData(),
                              ),
                            ),
                          );
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

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Transaction List (show max 10 on home page)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _transactions.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionItem(
                        transaction: _transactions[index],
                        onRefresh: _refreshWalletData,
                      ),
                    );
                  },
                  childCount:
                      _transactions.length > 10
                          ? 10
                          : _transactions.length, // Show max 10 transactions on home page
                ),
              ),

              // Add bottom padding to account for floating navigation
              SliverToBoxAdapter(child: const SizedBox(height: 100)),
            ],
          ),
          // Floating bottom navigation bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFF00FF00), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavButton(
                    'Receive',
                    Icons.keyboard_arrow_down,
                    onTap: () => showReceiveOptionsDialog(
                      context: context,
                      onEcashSelected: () => showEcashReceiveDialog(
                        context: context,
                        onSuccess: _refreshWalletData,
                      ),
                      onLightningSelected: () => showLightningReceiveDialog(
                        context: context,
                        onCreateInvoice: (amount, mintUrl) => _createLightningInvoice(amount, mintUrl: mintUrl),
                        onRefresh: _refreshWalletData,
                      ),
                    ),
                  ),
                  _buildBottomNavButton('Scan', Icons.qr_code_scanner, onTap: _showScanDialog),
                  _buildBottomNavButton('Send', Icons.keyboard_arrow_up, onTap: () => showSendOptionsDialog(
                    context: context,
                    onEcashSelected: () async {
                      await showEcashSendDialog(
                        context: context,
                        onCreateToken: (amount, memo, mintUrl) => _createEcashToken(amount, memo, mintUrl),
                        onRefresh: _refreshWalletData,
                      );
                    },
                    onLightningSelected: () => showLightningSendDialog(
                      context: context,
                      onPayInvoice: (invoice) => _payLightningInvoice(invoice),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    String title,
    String sats,
    String? usd,
    Gradient gradient,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
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
              Icon(icon, color: const Color(0xFF00FF00), size: 32),
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
          if (usd != null)
            Text(
              usd,
              style: const TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 14),
            ),
        ],
      ),
    );
  }


  Widget _buildBottomNavButton(String label, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00FF00), size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Receive ecash token
  Future<void> _receiveEcashToken(String token) async {
    // Validate token
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a token',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Receiving ecash token...',
          style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Call receiveTokens API
      final receivedAmount = await receiveTokens(token: token.trim());

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully received $receivedAmount sats!',
            style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh wallet data
      _refreshWalletData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to receive token: $e',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  /// Create a lightning invoice using new simplified API
  Future<void> _createLightningInvoice(int amount, {String? mintUrl}) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Creating lightning invoice...',
                  style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                ),
              ],
            ),
          );
        },
      );

      // Use provided mint URL or get the first available mint
      String? selectedMintUrl = mintUrl;

      if (selectedMintUrl == null) {
        final mints = await listMints();
        if (mints.isEmpty) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No mints available. Please add a mint first.',
                style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
              ),
              backgroundColor: Color(0xFF1A1A1A),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Extract mint URL from format "mint_url:unit" (e.g., "http://127.0.0.1:3338:sat")
        final mintString = mints.first;
        final lastColonIndex = mintString.lastIndexOf(':');
        selectedMintUrl =
            lastColonIndex != -1 ? mintString.substring(0, lastColonIndex) : mintString;
      }

      // Create mint quote using new simplified API
      final quote = await createMintQuote(mintUrl: selectedMintUrl, amount: BigInt.from(amount));

      final invoice = quote['request']!;
      final invoiceAmount = int.parse(quote['amount']!);

      Navigator.of(context).pop(); // Close loading dialog

      // Start specific monitoring for this mint URL
      WalletService.startMintQuoteMonitoring([selectedMintUrl]);

      // Show invoice dialog
      showInvoiceDisplayDialog(
        context: context,
        invoice: invoice,
        amount: invoiceAmount,
        mintUrl: selectedMintUrl,
        onPaymentReceived: (mintedAmount) => _showPaymentSuccess(mintedAmount),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create lightning invoice: $e',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show lightning invoice dialog and start monitoring automatically

  Future<void> _showScanDialog() async {
    // Navigate to QR scanner page
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );

    // Process the scanned result
    if (result != null && mounted) {
      if (result == '__MANUAL_INPUT__') {
        // User chose manual input
        showManualInputDialog(
          context: context,
          onProcess: (content) => _processScannedContent(content),
        );
      } else {
        // Process scanned QR code
        _processScannedContent(result);
      }
    }
  }


  void _processScannedContent(String content) {
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter content to process',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }


    // Trim whitespace
    final trimmedContent = content.trim();

    // Determine content type and process accordingly
    if (trimmedContent.toLowerCase().startsWith('cashu')) {
      // Cashu token - receive ecash (supports cashuA, cashuB, cashu1, etc.)
      _receiveEcashToken(trimmedContent);
    } else if (trimmedContent.toLowerCase().startsWith('lnbc') ||
        trimmedContent.toLowerCase().startsWith('lightning:')) {
      // Lightning invoice - send via lightning
      // Remove lightning: prefix if present
      final invoice =
          trimmedContent.startsWith('lightning:') ? trimmedContent.substring(10) : trimmedContent;
      showLightningSendDialog(
        context: context,
        onPayInvoice: (inv) => _payLightningInvoice(inv),
        initialInvoice: invoice,
      );
    } else {
      // Unknown format
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unknown content format. Expected Cashu token (cashu...) or Lightning invoice (lnbc...)',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }



  // P2PK related functions removed - will be implemented later


  Future<void> _createEcashToken(String amount, String memo, String mintUrl) async {
    // Validate amount
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an amount',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final int parsedAmount = int.tryParse(amount) ?? 0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (mintUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a mint',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Creating ecash token for $amount sats...',
                  style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                ),
              ],
            ),
          );
        },
      );

      // Parse mint URL to remove unit suffix (e.g., "http://127.0.0.1:3338:sat" -> "http://127.0.0.1:3338")
      String parsedMintUrl = mintUrl;
      final parts = mintUrl.split(':');
      if (parts.length >= 2) {
        parsedMintUrl = parts.sublist(0, parts.length - 1).join(':');
      }

      // Call sendTokens API
      final token = await sendTokens(
        mintUrl: parsedMintUrl,
        amount: BigInt.from(parsedAmount),
        memo: memo.isNotEmpty ? memo : null,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success dialog with token
      showEcashTokenDialog(
        context: context,
        token: token,
        amount: parsedAmount,
      );

      // Refresh wallet data
      _refreshWalletData();
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create token: $e',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show ecash token dialog after successful creation

  /// Show payment success message
  void _showPaymentSuccess(int mintedAmount) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment received! $mintedAmount sats minted to wallet',
          style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh wallet balance and transactions
    _refreshWalletData();
  }


  /// Refresh wallet data after minting
  Future<void> _refreshWalletData() async {
    try {
      // Use new bulk methods to get all data at once
      final allBalances = await getAllBalances();
      final allTransactions = await getAllTransactions();

      // Calculate total balance from all mints
      BigInt totalBalance = BigInt.zero;
      for (final balance in allBalances.values) {
        totalBalance += balance;
      }

      // Sort transactions by timestamp (newest first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Create aggregated wallet info
      final aggregatedWalletInfo = WalletInfo(
        mintUrl: 'Multiple Mints',
        unit: 'sat',
        balance: totalBalance,
        activeKeysetId: 'aggregated',
      );

      // Update UI
      setState(() {
        _walletInfo = aggregatedWalletInfo;
        _transactions = allTransactions;
      });
    } catch (e) {
      // Failed to refresh wallet data
    }
  }

  void _payLightningInvoice(String invoice) async {
    if (invoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a lightning invoice',
            style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paying lightning invoice...',
                  style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                ),
              ],
            ),
          );
        },
      );

      // Get the first mint URL
      final mints = await listMints();
      if (mints.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No mints available. Please add a mint first.',
              style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
            ),
            backgroundColor: Color(0xFF1A1A1A),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Extract mint URL from format "mint_url:unit"
      final mintString = mints.first;
      final lastColonIndex = mintString.lastIndexOf(':');
      final mintUrl = lastColonIndex != -1 ? mintString.substring(0, lastColonIndex) : mintString;

      // Pay lightning invoice using new API
      final paymentStatus = await payInvoiceForWallet(
        mintUrl: mintUrl,
        bolt11Invoice: invoice,
        maxFeeSats: BigInt.from(100), // Max fee of 100 sats
      );

      Navigator.of(context).pop(); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lightning payment completed! Status: $paymentStatus',
            style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh wallet balance and transactions
      _refreshWalletData();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pay lightning invoice: $e',
            style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show transaction detail dialog

  /// Build detail row for transaction details

  @override
  void dispose() {
    // Stop specific monitoring when page is disposed, but keep global monitoring running
    WalletService.stopMintQuoteMonitoring();
    WalletService.stopMeltQuoteMonitoring();
    // Don't stop global monitoring - it should continue running in the background
    super.dispose();
  }
}
