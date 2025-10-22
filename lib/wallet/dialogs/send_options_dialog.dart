import 'package:flutter/material.dart';

/// Show send options dialog
Future<void> showSendOptionsDialog({
  required BuildContext context,
  required VoidCallback onEcashSelected,
  required VoidCallback onLightningSelected,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Send',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF00FF00)),
              title: const Text(
                'Ecash',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
              subtitle: const Text(
                'Create Cashu token and share',
                style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
              ),
              onTap: () {
                Navigator.of(dialogContext).pop();
                onEcashSelected();
              },
            ),
            const Divider(color: Color(0xFF333333)),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Color(0xFF00FF00)),
              title: const Text(
                'Lightning',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              ),
              subtitle: const Text(
                'Withdraw funds by paying invoice',
                style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
              ),
              onTap: () {
                Navigator.of(dialogContext).pop();
                onLightningSelected();
              },
            ),
          ],
        ),
      );
    },
  );
}

