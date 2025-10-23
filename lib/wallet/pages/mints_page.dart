import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import '../services/wallet_service.dart';

/// Mints management page
class MintsPage extends StatefulWidget {
  const MintsPage({super.key});

  @override
  State<MintsPage> createState() => _MintsPageState();
}

class _MintsPageState extends State<MintsPage> {
  List<String> _mints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMints();
  }

  Future<void> _loadMints() async {
    try {
      final mints = await listMints();
      if (mounted) {
        setState(() {
          _mints = mints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Validate mint URL to support various protocols and address types
  bool _isValidMintUrl(String url) {
    if (url.isEmpty) return false;

    // Remove trailing slashes
    url = url.trim().replaceAll(RegExp(r'/+$'), '');

    // Check for supported protocols
    final supportedProtocols = ['http', 'https'];
    final hasProtocol = supportedProtocols.any(
      (protocol) => url.toLowerCase().startsWith('$protocol://'),
    );

    if (!hasProtocol) {
      // If no protocol specified, assume https
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);

      // Check if it's a valid URI
      if (!uri.hasScheme || !uri.hasAuthority) return false;

      // Validate scheme
      if (!supportedProtocols.contains(uri.scheme.toLowerCase())) return false;

      // Check for various address types
      final host = uri.host.toLowerCase();

      // Local addresses
      if (host == 'localhost' || host == '127.0.0.1') return true;

      // Private network ranges
      if (host.startsWith('192.168.') || host.startsWith('10.') || host.startsWith('172.')) {
        return true;
      }

      // Tor .onion addresses
      if (host.endsWith('.onion')) return true;

      // Regular domain names (must contain at least one dot)
      if (host.contains('.') && !host.startsWith('.') && !host.endsWith('.')) return true;

      // IP addresses (IPv4)
      final ipv4Regex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
      if (ipv4Regex.hasMatch(host)) {
        final parts = host.split('.');
        for (final part in parts) {
          final num = int.tryParse(part);
          if (num == null || num < 0 || num > 255) return false;
        }
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void _showAddMintDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController aliasController = TextEditingController();
    String? urlError;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Add New Mint',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mint URL:',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    decoration: InputDecoration(
                      hintText: 'https://mint.example.com or localhost:3338',
                      hintStyle: const TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      errorText: urlError,
                      errorStyle: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontFamily: 'Courier',
                        fontSize: 10,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final isValid = _isValidMintUrl(value);
                        setState(() {
                          urlError = isValid ? null : 'Invalid URL format';
                        });
                      } else {
                        setState(() {
                          urlError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alias (optional):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aliasController,
                    style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    decoration: const InputDecoration(
                      hintText: 'My Local Mint',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF00))),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supported formats:',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• HTTPS: https://mint.example.com\n'
                    '• HTTP: http://localhost:3338\n'
                    '• Local: localhost:3338 or 127.0.0.1:3338\n'
                    '• LAN: 192.168.1.100:3338\n'
                    '• Tor: abc123def.onion:3338',
                    style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    var url = urlController.text.trim();
                    final alias = aliasController.text.trim();

                    if (url.isEmpty) {
                      setState(() {
                        urlError = 'URL is required';
                      });
                      return;
                    }

                    if (!_isValidMintUrl(url)) {
                      setState(() {
                        urlError = 'Invalid URL format';
                      });
                      return;
                    }

                    // Add https:// if no protocol specified
                    if (!url.toLowerCase().startsWith('http://') &&
                        !url.toLowerCase().startsWith('https://')) {
                      url = 'https://$url';
                    }

                    // Add the mint
                    Navigator.of(context).pop();
                    _addMint(url, alias.isNotEmpty ? alias : 'Mint');
                  },
                  child: const Text(
                    'Add Mint',
                    style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMint(String mintUrl, String alias) async {
    try {
      // Check if this is an onion address
      final isOnion = mintUrl.contains('.onion');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnion ? 'Initializing Tor connection...' : 'Adding mint...',
              style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: Duration(seconds: isOnion ? 3 : 1),
          ),
        );
      }

      // For onion addresses, show a dialog
      if (isOnion && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00FF00)),
                    const SizedBox(height: 20),
                    const Text(
                      'Connecting to Tor network...',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This may take 30-60 seconds\nPlease wait...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Add the mint using WalletService (handles Tor configuration for .onion)
      await WalletService.addMintService(mintUrl, 'sat');
      
      // Close the Tor connection dialog if it was shown
      if (isOnion && mounted) {
        Navigator.of(context).pop();
      }

      // Reload mints
      await _loadMints();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mint added successfully: $alias',
              style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      
      // Close the Tor connection dialog if it was shown
      final isOnion = mintUrl.contains('.onion');
      if (isOnion && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add mint: $e',
              style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showMintDetailDialog(String mintUrl, String alias) {
    final TextEditingController aliasController = TextEditingController(text: alias);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Mint Details',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mint URL:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                mintUrl,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alias:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aliasController,
                style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                decoration: const InputDecoration(
                  hintText: 'Enter alias for this mint',
                  hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF00))),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00FF00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteMintConfirmation(mintUrl, aliasController.text);
                      },
                      icon: const Icon(Icons.delete, color: Color(0xFFFF6B6B), size: 16),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFFF6B6B)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMintAlias(mintUrl, aliasController.text);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMintConfirmation(String mintUrl, String alias) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Mint',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this mint?',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
              const SizedBox(height: 8),
              Text(
                'Alias: $alias',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              Text(
                'URL: $mintUrl',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier', fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMint(mintUrl);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateMintAlias(String mintUrl, String newAlias) {
    // TODO: Update mint alias in storage
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mint alias updated to: $newAlias',
          style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteMint(String mintUrl) async {
    try {
      // Call the API to remove the mint
      await removeMint(mintUrl: mintUrl);
      
      // Reload mints list
      await _loadMints();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mint deleted: $mintUrl',
              style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete mint: $e',
              style: const TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
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
        title: const Text(
          'MINTS',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF00)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _mints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF666666),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No mints configured',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontFamily: 'Courier',
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add a mint to get started',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _mints.length,
                          itemBuilder: (context, index) {
                            final mint = _mints[index];
                            final parts = mint.split(':');
                            final mintUrl = parts.isNotEmpty ? parts[0] : mint;
                            final unit = parts.length > 1 ? parts[1] : 'sat';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  _showMintDetailDialog(mintUrl, 'Mint');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    border: Border.all(color: const Color(0xFF00FF00)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet,
                                        color: Color(0xFF00FF00),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mintUrl,
                                              style: const TextStyle(
                                                color: Color(0xFF00FF00),
                                                fontFamily: 'Courier',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Unit: $unit',
                                              style: const TextStyle(
                                                color: Color(0xFF666666),
                                                fontFamily: 'Courier',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF666666),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _showAddMintDialog,
                    icon: const Icon(Icons.add, color: Color(0xFF00FF00)),
                    label: const Text(
                      'Add New Mint',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFF00FF00)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

