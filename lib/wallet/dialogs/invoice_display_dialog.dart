import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart';

/// Show lightning invoice display dialog
void showInvoiceDisplayDialog({
  required BuildContext context,
  required String invoice,
  required int amount,
  required String mintUrl,
  required Function(int mintedAmount) onPaymentReceived,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Lightning Invoice Created',
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
                Text(
                  'Amount: $amount sats',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // QR Code display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFF00FF00), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: invoice,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFF00FF00),
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invoice:',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: invoice));
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invoice copied to clipboard!',
                            style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                          ),
                          backgroundColor: Color(0xFF1A1A1A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00FF00)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                              fontSize: 10,
                            ),
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
                  'Share this invoice with the sender to receive payment.',
                  style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Close',
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

  // Set up callback for payment received
  WalletService.onMintedAmountReceived = (result) {
    final mintedAmount = int.parse(result['total_minted'] ?? '0');
    if (mintedAmount > 0) {
      onPaymentReceived(mintedAmount);
      WalletService.stopMintQuoteMonitoring();
    }
  };

  // Start monitoring using WalletService
  WalletService.startMintQuoteMonitoring([mintUrl]);
}

