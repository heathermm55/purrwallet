import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Show ecash token display dialog
Future<void> showEcashTokenDialog({
  required BuildContext context,
  required String token,
  required int amount,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Ecash Token Created',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Center(
                  child: Text(
                    '$amount sats',
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code (only if token is not too long)
                if (token.length <= 2000) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(color: const Color(0xFF00FF00), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: token.toUpperCase(),
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: const Color(0xFF00FF00),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      border: Border.all(color: const Color(0xFFFF6B6B), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.qr_code_2, color: Color(0xFF666666), size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Token too long for QR code',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please copy the token below',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Token text (clickable to copy)
                const Text(
                  'Token:',
                  style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Token copied to clipboard',
                          style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                        ),
                        backgroundColor: Color(0xFF1A1A1A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00FF00)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            token,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, color: Color(0xFF00FF00), size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share this token to send ecash.',
                  style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Done',
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

