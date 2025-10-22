import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

/// Show ecash receive dialog
Future<void> showEcashReceiveDialog({
  required BuildContext context,
  required VoidCallback onSuccess,
}) async {
  final TextEditingController tokenController = TextEditingController();

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Receive Ecash',
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
                'Paste Cashu token:',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tokenController,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'cashuA...',
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
                      onPressed: () async {
                        // Paste from clipboard
                        final clipboardData = await Clipboard.getData('text/plain');
                        if (clipboardData != null && clipboardData.text != null) {
                          tokenController.text = clipboardData.text!;
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Token pasted from clipboard',
                                  style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                                ),
                                backgroundColor: Color(0xFF1A1A1A),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } else {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Clipboard is empty',
                                  style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
                                ),
                                backgroundColor: Color(0xFF1A1A1A),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.content_paste, color: Color(0xFF00FF00), size: 16),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The token will be automatically redeemed and added to your wallet.',
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
              final token = tokenController.text;
              Navigator.of(dialogContext).pop();
              
              // Validate token
              if (token.isEmpty) {
                if (context.mounted) {
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
                }
                return;
              }

              // Show loading message
              if (context.mounted) {
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
              }

              try {
                // Call receiveTokens API
                final receivedAmount = await receiveTokens(token: token.trim());

                // Show success message
                if (context.mounted) {
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
                  onSuccess();
                }
              } catch (e) {
                if (context.mounted) {
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
            },
            child: const Text(
              'Receive',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

