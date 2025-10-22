import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

/// Show transaction detail dialog
Future<void> showTransactionDetailDialog({
  required BuildContext context,
  required TransactionInfo transaction,
  required VoidCallback onRefresh,
}) async {
  final tx = transaction;
  final isReceived = tx.direction == 'incoming';
  final time = DateTime.fromMillisecondsSinceEpoch((tx.timestamp * BigInt.from(1000)).toInt());
  final dateStr =
      '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Get transaction type for title
  final txType = tx.transactionType ?? 'unknown';
  String dialogTitle;
  switch (txType) {
    case 'lightning_receive':
      dialogTitle = 'Lightning Receive';
      break;
    case 'lightning_send':
      dialogTitle = 'Lightning Send';
      break;
    case 'ecash_receive':
      dialogTitle = 'Ecash Receive';
      break;
    case 'ecash_send':
      dialogTitle = 'Ecash Send';
      break;
    default:
      dialogTitle = isReceived ? 'Received' : 'Sent';
  }

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          dialogTitle,
          style: const TextStyle(
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
                _buildDetailRow('Amount', '${tx.amount} sats'),
                const SizedBox(height: 12),

                // Transaction Type
                _buildDetailRow('Type', dialogTitle),
                const SizedBox(height: 12),

                // Date
                _buildDetailRow('Date', dateStr),
                const SizedBox(height: 12),

                // Memo (if exists)
                if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                  _buildDetailRow('Memo', tx.memo!),
                  const SizedBox(height: 12),
                ],

                // Lightning Invoice (if exists and is lightning transaction)
                if ((txType == 'lightning_receive' || txType == 'lightning_send') && 
                    tx.lightningInvoice != null && tx.lightningInvoice!.isNotEmpty) ...[
                  _buildDetailRow(
                    'Lightning Invoice',
                    tx.lightningInvoice!.length > 100
                        ? '${tx.lightningInvoice!.substring(0, 100)}...'
                        : tx.lightningInvoice!,
                    isMonospace: true,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tx.lightningInvoice!));
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Color(0xFF00FF00)),
                    label: const Text(
                      'Copy Invoice',
                      style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      side: const BorderSide(color: Color(0xFF00FF00)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Ecash Token (if exists and is ecash transaction)
                if ((txType == 'ecash_receive' || txType == 'ecash_send') && 
                    tx.ecashToken != null && tx.ecashToken!.isNotEmpty) ...[
                  _buildDetailRow(
                    'Ecash Token',
                    tx.ecashToken!.length > 100
                        ? '${tx.ecashToken!.substring(0, 100)}...'
                        : tx.ecashToken!,
                    isMonospace: true,
                  ),
                  const SizedBox(height: 8),
                  // For ecash_send, show "Claim Token" button, otherwise "Copy Token"
                  if (txType == 'ecash_send')
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop(); // Close dialog first
                        try {
                          final amount = await receiveTokens(token: tx.ecashToken!);
                          if (context.mounted) {
                            onRefresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Claimed $amount sats'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to claim token: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download, size: 16, color: Color(0xFF00FF00)),
                      label: const Text(
                        'Claim Token',
                        style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tx.ecashToken!));
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Token copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF00FF00)),
                      label: const Text(
                        'Copy Token',
                        style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
}

/// Build detail row for transaction details
Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label:',
        style: const TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 12),
      ),
      const SizedBox(height: 4),
      SelectableText(
        value,
        style: TextStyle(
          color: const Color(0xFF00FF00),
          fontFamily: isMonospace ? 'Courier' : null,
          fontSize: 12,
        ),
      ),
    ],
  );
}

