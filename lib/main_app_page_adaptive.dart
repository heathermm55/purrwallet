import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:math';
import 'settings/main_settings_page.dart';
import 'settings/mints_page.dart';
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
import 'utils/responsive_layout.dart';

/// Adaptive main app page - Wallet interface with split view support
class MainAppPageAdaptive extends StatefulWidget {
  const MainAppPageAdaptive({super.key});

  @override
  State<MainAppPageAdaptive> createState() => _MainAppPageAdaptiveState();
}

class _MainAppPageAdaptiveState extends State<MainAppPageAdaptive> {
  // Cashu Wallet state
  WalletInfo? _walletInfo;
  List<TransactionInfo> _transactions = [];
  
  // Split view state
  String _selectedDetailView = 'home'; // 'home', 'transactions', 'mints', or 'settings'

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
    final useSplitView = ResponsiveLayout.shouldUseSplitView(context);

    return AdaptiveScaffold(
      title: 'PURRWALLET',
      actions: [
        if (!useSplitView)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings, color: Color(0xFF00FF00)),
          ),
      ],
      masterPane: _buildMasterPane(),
      detailPane: useSplitView ? _buildDetailPane() : null,
    );
  }

  /// Build master pane (left side in split view, full screen in mobile)
  Widget _buildMasterPane() {
    // In split view, show compact sidebar menu (IRC style)
    if (ResponsiveLayout.shouldUseSplitView(context)) {
      return Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Menu items
            _buildSidebarMenuItem(
              'Home',
              Icons.home,
              'home',
            ),
            const SizedBox(height: 4),
            _buildSidebarMenuItem(
              'Transactions',
              Icons.receipt_long,
              'transactions',
            ),
            const SizedBox(height: 4),
            _buildSidebarMenuItem(
              'Mints',
              Icons.account_balance_wallet,
              'mints',
            ),
            const SizedBox(height: 4),
            _buildSidebarMenuItem(
              'Settings',
              Icons.settings,
              'settings',
            ),
          ],
        ),
      );
    }

    // In mobile view, show full home page
    return Stack(
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

            // Transaction preview for mobile
            if (!ResponsiveLayout.shouldUseSplitView(context))
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

            if (!ResponsiveLayout.shouldUseSplitView(context))
              SliverToBoxAdapter(child: const SizedBox(height: 16)),

            // Transaction List preview for mobile (show max 10 on home page)
            if (!ResponsiveLayout.shouldUseSplitView(context))
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
                  childCount: _transactions.length > 10 ? 10 : _transactions.length,
                ),
              ),

            // Add bottom padding
            SliverToBoxAdapter(child: const SizedBox(height: 100)),
          ],
        ),
        
        // Floating bottom navigation bar (only for mobile)
        if (!ResponsiveLayout.shouldUseSplitView(context))
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
                        onCreateInvoice: (amount, mintUrl) =>
                            _createLightningInvoice(amount, mintUrl: mintUrl),
                        onRefresh: _refreshWalletData,
                      ),
                    ),
                  ),
                  _buildBottomNavButton('Scan', Icons.qr_code_scanner, onTap: _showScanDialog),
                  _buildBottomNavButton(
                    'Send',
                    Icons.keyboard_arrow_up,
                    onTap: () => showSendOptionsDialog(
                      context: context,
                      onEcashSelected: () async {
                        await showEcashSendDialog(
                          context: context,
                          onCreateToken: (amount, memo, mintUrl) =>
                              _createEcashToken(amount, memo, mintUrl),
                          onRefresh: _refreshWalletData,
                        );
                      },
                      onLightningSelected: () => showLightningSendDialog(
                        context: context,
                        onPayInvoice: (invoice) => _payLightningInvoice(invoice),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build detail pane (right side in split view)
  Widget _buildDetailPane() {
    switch (_selectedDetailView) {
      case 'home':
        return _buildHomeView();
      case 'transactions':
        return _buildTransactionsView();
      case 'mints':
        return _buildMintsView();
      case 'settings':
        return _buildSettingsView();
      default:
        return _buildHomeView();
    }
  }

  /// Build home view for detail pane (like mobile home page)
  Widget _buildHomeView() {
    return Container(
      color: Colors.black,
      child: Stack(
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
                    null,
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
                          setState(() {
                            _selectedDetailView = 'transactions';
                          });
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

              // Transaction List (show max 10)
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
                  childCount: _transactions.length > 10 ? 10 : _transactions.length,
                ),
              ),

              // Add bottom padding
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
                        onCreateInvoice: (amount, mintUrl) =>
                            _createLightningInvoice(amount, mintUrl: mintUrl),
                        onRefresh: _refreshWalletData,
                      ),
                    ),
                  ),
                  _buildBottomNavButton('Scan', Icons.qr_code_scanner, onTap: _showScanDialog),
                  _buildBottomNavButton(
                    'Send',
                    Icons.keyboard_arrow_up,
                    onTap: () => showSendOptionsDialog(
                      context: context,
                      onEcashSelected: () async {
                        await showEcashSendDialog(
                          context: context,
                          onCreateToken: (amount, memo, mintUrl) =>
                              _createEcashToken(amount, memo, mintUrl),
                          onRefresh: _refreshWalletData,
                        );
                      },
                      onLightningSelected: () => showLightningSendDialog(
                        context: context,
                        onPayInvoice: (invoice) => _payLightningInvoice(invoice),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build transactions view for detail pane
  Widget _buildTransactionsView() {
    return Container(
      color: Colors.black,
      child: _transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Color(0xFF666666),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(
                  transaction: _transactions[index],
                  onRefresh: _refreshWalletData,
                );
              },
            ),
    );
  }

  /// Build mints view for detail pane
  Widget _buildMintsView() {
    return Container(
      color: Colors.black,
      child: const MintsPage(embedded: true),
    );
  }

  /// Build settings view for detail pane
  Widget _buildSettingsView() {
    return Container(
      color: Colors.black,
      child: const SettingsPage(embedded: true),
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

  /// Build sidebar menu item for split view (IRC style)
  Widget _buildSidebarMenuItem(String label, IconData icon, String view) {
    final isSelected = _selectedDetailView == view;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDetailView = view;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF666666),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF888888),
                  fontFamily: 'Courier',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All wallet operation methods remain the same as original MainAppPage
  Future<void> _receiveEcashToken(String token) async {
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
      final receivedAmount = await receiveTokens(token: token.trim());

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

  Future<void> _createLightningInvoice(int amount, {String? mintUrl}) async {
    try {
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

      String? selectedMintUrl = mintUrl;

      if (selectedMintUrl == null) {
        final mints = await listMints();
        if (mints.isEmpty) {
          Navigator.of(context).pop();
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

        final mintString = mints.first;
        final lastColonIndex = mintString.lastIndexOf(':');
        selectedMintUrl =
            lastColonIndex != -1 ? mintString.substring(0, lastColonIndex) : mintString;
      }

      final quote = await createMintQuote(mintUrl: selectedMintUrl, amount: BigInt.from(amount));

      final invoice = quote['request']!;
      final invoiceAmount = int.parse(quote['amount']!);

      Navigator.of(context).pop();

      WalletService.startMintQuoteMonitoring([selectedMintUrl]);

      showInvoiceDisplayDialog(
        context: context,
        invoice: invoice,
        amount: invoiceAmount,
        mintUrl: selectedMintUrl,
        onPaymentReceived: (mintedAmount) => _showPaymentSuccess(mintedAmount),
      );
    } catch (e) {
      Navigator.of(context).pop();
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

  Future<void> _showScanDialog() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );

    if (result != null && mounted) {
      if (result == '__MANUAL_INPUT__') {
        showManualInputDialog(
          context: context,
          onProcess: (content) => _processScannedContent(content),
        );
      } else {
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

    final trimmedContent = content.trim();

    if (trimmedContent.toLowerCase().startsWith('cashu')) {
      _receiveEcashToken(trimmedContent);
    } else if (trimmedContent.toLowerCase().startsWith('lnbc') ||
        trimmedContent.toLowerCase().startsWith('lightning:')) {
      final invoice =
          trimmedContent.startsWith('lightning:') ? trimmedContent.substring(10) : trimmedContent;
      showLightningSendDialog(
        context: context,
        onPayInvoice: (inv) => _payLightningInvoice(inv),
        initialInvoice: invoice,
      );
    } else {
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

  Future<void> _createEcashToken(String amount, String memo, String mintUrl) async {
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

      String parsedMintUrl = mintUrl;
      final parts = mintUrl.split(':');
      if (parts.length >= 2) {
        parsedMintUrl = parts.sublist(0, parts.length - 1).join(':');
      }

      final token = await sendTokens(
        mintUrl: parsedMintUrl,
        amount: BigInt.from(parsedAmount),
        memo: memo.isNotEmpty ? memo : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      showEcashTokenDialog(
        context: context,
        token: token,
        amount: parsedAmount,
      );

      _refreshWalletData();
    } catch (e) {
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

  void _showPaymentSuccess(int mintedAmount) {
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

    _refreshWalletData();
  }

  Future<void> _refreshWalletData() async {
    try {
      final allBalances = await getAllBalances();
      final allTransactions = await getAllTransactions();

      BigInt totalBalance = BigInt.zero;
      for (final balance in allBalances.values) {
        totalBalance += balance;
      }

      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final aggregatedWalletInfo = WalletInfo(
        mintUrl: 'Multiple Mints',
        unit: 'sat',
        balance: totalBalance,
        activeKeysetId: 'aggregated',
      );

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

      final mints = await listMints();
      if (mints.isEmpty) {
        Navigator.of(context).pop();
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

      final mintString = mints.first;
      final lastColonIndex = mintString.lastIndexOf(':');
      final mintUrl = lastColonIndex != -1 ? mintString.substring(0, lastColonIndex) : mintString;

      final paymentStatus = await payInvoiceForWallet(
        mintUrl: mintUrl,
        bolt11Invoice: invoice,
        maxFeeSats: BigInt.from(100),
      );

      Navigator.of(context).pop();

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

      _refreshWalletData();
    } catch (e) {
      Navigator.of(context).pop();
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

  @override
  void dispose() {
    WalletService.stopMintQuoteMonitoring();
    WalletService.stopMeltQuoteMonitoring();
    super.dispose();
  }
}

