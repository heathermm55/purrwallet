import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

/// Show add mint dialog
Future<void> showAddMintDialog({
  required BuildContext context,
  required VoidCallback onMintAdded,
}) async {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController aliasController = TextEditingController();
  String? urlError;

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
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
            content: SingleChildScrollView(
              child: Column(
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                ),
              ),
              TextButton(
                onPressed: () async {
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

                  // Close dialog first
                  Navigator.of(dialogContext).pop();

                  // Add the mint
                  await _addMint(context, url, alias.isNotEmpty ? alias : 'Mint', onMintAdded);
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
    if (uri.host.isEmpty) return false;

    // Check for onion addresses (Tor hidden services)
    if (uri.host.endsWith('.onion')) return true;

    // Check for localhost/127.0.0.1
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') return true;

    // Check for LAN addresses (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
    final ipPattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    final ipMatch = ipPattern.firstMatch(uri.host);
    if (ipMatch != null) {
      final first = int.parse(ipMatch.group(1)!);
      if (first == 192 || first == 10 || (first == 172)) {
        return true;
      }
    }

    // Check for domain names (must have at least one dot)
    if (uri.host.contains('.')) return true;

    return false;
  } catch (e) {
    return false;
  }
}

/// Add mint to wallet
Future<void> _addMint(
  BuildContext context,
  String mintUrl,
  String alias,
  VoidCallback onSuccess,
) async {
  try {
    // Check if this is an onion address
    final isOnion = mintUrl.contains('.onion');

    // Show loading dialog for all cases
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOnion ? 'Connecting via Tor...' : 'Adding mint...',
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOnion ? 'This may take a moment' : 'Please wait...',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Call the Rust API to add the mint (alias is stored internally by the wallet)
    await addMint(mintUrl: mintUrl);

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added mint: $alias',
            style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Call success callback
    onSuccess();
  } catch (e) {
    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show error message
    if (context.mounted) {
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

