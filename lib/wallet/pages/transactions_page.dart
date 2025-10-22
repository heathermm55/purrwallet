import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import '../dialogs/transaction_detail_dialog.dart';

/// All transactions page
class TransactionsPage extends StatelessWidget {
  final List<TransactionInfo> transactions;
  final Function(TransactionInfo)? onRefresh;

  const TransactionsPage({
    super.key,
    required this.transactions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ALL TRANSACTIONS',
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
      body: transactions.isEmpty
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
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(context, transactions[index]);
              },
            ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionInfo tx) {
    final isReceived = tx.direction == 'incoming';
    final time = DateTime.fromMillisecondsSinceEpoch((tx.timestamp * BigInt.from(1000)).toInt());
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Determine transaction type and display info
    final txType = tx.transactionType ?? 'unknown';
    IconData txIcon;
    String txLabel;
    Color txColor;

    switch (txType) {
      case 'lightning_receive':
        txIcon = Icons.flash_on;
        txLabel = 'Lightning Receive';
        txColor = const Color(0xFFFFA500); // Orange
        break;
      case 'lightning_send':
        txIcon = Icons.flash_on;
        txLabel = 'Lightning Send';
        txColor = const Color(0xFFFFA500); // Orange
        break;
      case 'ecash_receive':
        txIcon = Icons.monetization_on;
        txLabel = 'Ecash Receive';
        txColor = Colors.green;
        break;
      case 'ecash_send':
        txIcon = Icons.monetization_on;
        txLabel = 'Ecash Send';
        txColor = Colors.red;
        break;
      default:
        txIcon = isReceived ? Icons.arrow_downward : Icons.arrow_upward;
        txLabel = isReceived ? 'Received' : 'Sent';
        txColor = isReceived ? Colors.green : Colors.red;
    }

    return InkWell(
      onTap: () => showTransactionDetailDialog(
        context: context,
        transaction: tx,
        onRefresh: () {
          if (onRefresh != null) {
            onRefresh!(tx);
          }
        },
      ),
      child: Container(
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
                color: txColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(txIcon, color: txColor, size: 20),
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
                    txLabel,
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
                  style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
