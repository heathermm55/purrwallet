import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'mint_detail_page.dart';

/// Mints management page with add/remove functionality
class MintsPage extends StatefulWidget {
  const MintsPage({super.key});

  @override
  State<MintsPage> createState() => _MintsPageState();
}

class _MintsPageState extends State<MintsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Mints',
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
      body: FutureBuilder<List<String>>(
        future: Future(() => listMints()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading mints...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF6B6B),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading mints: ${snapshot.error}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontFamily: 'Courier',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final mints = snapshot.data ?? [];

          if (mints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF666666),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No mints configured',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first mint to get started',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddMintDialog,
                    icon: const Icon(Icons.add, color: Color(0xFF00FF00)),
                    label: const Text(
                      'Add Mint',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFF00FF00)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mints.length,
            itemBuilder: (context, index) {
              final mint = mints[index];
              
              // Parse mint string format: "mint_url:unit"
              // The unit is always one of: "sat", "usd", "eur"
              String mintUrl;
              String unit;
              
              // Find the last occurrence of ":sat", ":usd", or ":eur"
              if (mint.endsWith(':sat')) {
                mintUrl = mint.substring(0, mint.length - 4); // Remove ":sat"
                unit = 'sat';
              } else if (mint.endsWith(':usd')) {
                mintUrl = mint.substring(0, mint.length - 4); // Remove ":usd"
                unit = 'usd';
              } else if (mint.endsWith(':eur')) {
                mintUrl = mint.substring(0, mint.length - 4); // Remove ":eur"
                unit = 'eur';
              } else {
                // Fallback: treat as URL only
                mintUrl = mint;
                unit = 'sat';
              }

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF00FF00), width: 1),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF00FF00),
                  ),
                  title: Text(
                    mintUrl,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Unit: $unit',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MintDetailPage(
                          mintUrl: mintUrl,
                          unit: unit,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMintDialog,
        backgroundColor: const Color(0xFF00FF00),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddMintDialog() {
    final TextEditingController urlController = TextEditingController();
    String? urlError;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Add Mint',
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
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    decoration: InputDecoration(
                      hintText: 'mint.example.com or localhost:3338',
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
                    '• Auto HTTPS: mint.example.com\n'
                    '• Local: localhost:3338\n'
                    '• Tor: abc123def.onion:3338',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final url = urlController.text.trim();

                    if (url.isEmpty) {
                      setState(() {
                        urlError = 'URL is required';
                      });
                      return;
                    }

                    // Auto-add https if no protocol specified
                    final processedUrl = _processMintUrl(url);

                    if (!_isValidMintUrl(processedUrl)) {
                      setState(() {
                        urlError = 'Invalid URL format';
                      });
                      return;
                    }

                    // Add the mint
                    Navigator.of(context).pop();
                    _addMint(processedUrl);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Process mint URL to add https if no protocol specified
  String _processMintUrl(String url) {
    if (url.isEmpty) return url;

    // Remove trailing slashes
    url = url.trim().replaceAll(RegExp(r'/+$'), '');

    // Check if protocol is already specified
    if (url.toLowerCase().startsWith('http://') || url.toLowerCase().startsWith('https://')) {
      return url;
    }

    // Auto-add https for URLs that look like domains or IPs
    if (url.contains('.') || RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(url)) {
      return 'https://$url';
    }

    // For localhost or IP addresses without dots, add https
    if (url.startsWith('localhost') || RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(url)) {
      return 'https://$url';
    }

    // For Tor .onion addresses, add https
    if (url.endsWith('.onion')) {
      return 'https://$url';
    }

    // Default to https for any other case
    return 'https://$url';
  }

  /// Validate mint URL to support various protocols and address types
  bool _isValidMintUrl(String url) {
    if (url.isEmpty) return false;

    // Remove trailing slashes
    url = url.trim().replaceAll(RegExp(r'/+$'), '');

    // Check for supported protocols
    final supportedProtocols = ['http', 'https'];
    final hasProtocol = supportedProtocols.any((protocol) => url.toLowerCase().startsWith('$protocol://'));

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
      if (host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.')) {
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

  void _addMint(String mintUrl) async {
    try {
      // Use the processed URL from the dialog (already has correct format)
      print('Adding mint with URL: $mintUrl');
      
      // Add the mint using the Rust API
      final result = addMint(mintUrl: mintUrl);
      print('Add mint result: $result');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mint added successfully: $mintUrl',
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      print('Failed to add mint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add mint: $e',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeMint(String mintUrl) async {
    try {
      // Use the exact URL as stored (no processing needed)
      print('Removing mint with URL: $mintUrl');
      
      // Remove the mint using the Rust API
      final result = removeMint(mintUrl: mintUrl);
      print('Remove mint result: $result');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mint removed successfully: $mintUrl',
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      print('Failed to remove mint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove mint: $e',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
