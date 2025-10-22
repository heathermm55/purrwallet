import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Show manual input dialog
Future<void> showManualInputDialog({
  required BuildContext context,
  required Function(String content) onProcess,
}) async {
  final TextEditingController controller = TextEditingController();

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Manual Input',
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
              'Enter QR code content:',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Paste Cashu token or Lightning invoice...',
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
                        controller.text = clipboardData.text!;
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Content pasted from clipboard',
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
          ],
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
            onPressed: () {
              final content = controller.text;
              if (content.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
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
              Navigator.of(dialogContext).pop();
              onProcess(content);
            },
            child: const Text(
              'Process',
              style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
            ),
          ),
        ],
      );
    },
  );
}

