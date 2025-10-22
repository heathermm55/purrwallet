import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import '../pages/mints_page.dart';

/// Show ecash send dialog
Future<void> showEcashSendDialog({
  required BuildContext context,
  required Function(String amount, String memo, String mintUrl) onCreateToken,
  required VoidCallback onRefresh,
}) async {
  // Load available mints first
  List<String> mints = [];
  try {
    mints = await listMints();
  } catch (e) {
    // Error loading mints
  }

  if (mints.isEmpty) {
    // Show alert to add mint first
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'No Mint Available',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please add a mint first before sending ecash.',
            style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
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
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MintsPage()),
                ).then((_) => onRefresh());
              },
              child: const Text(
                'Add Mint',
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

  // Parse mint URLs to display format
  final parsedMints = mints.map((mint) {
    final parts = mint.split(':');
    if (parts.length >= 2) {
      return parts.sublist(0, parts.length - 1).join(':');
    }
    return mint;
  }).toList();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  String selectedMint = parsedMints[0]; // Default to first mint
  String selectedMintFull = mints[0]; // Keep full mint URL for API call

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Send Ecash',
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
                  // Mint Selection Dropdown
                  const Text(
                    'Select Mint:',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00FF00)),
                    ),
                    child: DropdownButton<String>(
                      value: selectedMint,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      items: List.generate(parsedMints.length, (index) {
                        final displayText = parsedMints[index];
                        return DropdownMenuItem<String>(
                          value: displayText,
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                            ),
                          ),
                        );
                      }),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMint = newValue;
                            // Find the corresponding full mint URL
                            final index = parsedMints.indexOf(newValue);
                            if (index >= 0 && index < mints.length) {
                              selectedMintFull = mints[index];
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const Text(
                    'Amount (sats):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 18,
                    ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Memo (optional)
                  const Text(
                    'Memo (optional):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoController,
                    style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    decoration: const InputDecoration(
                      hintText: 'Add a note',
                      hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF00)),
                      ),
                    ),
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCreateToken(amountController.text, memoController.text, selectedMintFull);
                },
                child: const Text(
                  'Create Token',
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
    },
  );
}

