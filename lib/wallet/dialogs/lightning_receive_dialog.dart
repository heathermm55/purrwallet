import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import '../pages/mints_page.dart';

/// Show lightning receive dialog
Future<void> showLightningReceiveDialog({
  required BuildContext context,
  required Function(int amount, String mintUrl) onCreateInvoice,
  required VoidCallback onRefresh,
}) async {
  // Check if there are any mints available first
  final mints = await listMints();
  if (mints.isEmpty) {
    // Show dialog to prompt user to add a mint
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'No Mints Available',
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You need to add a mint first before you can receive via lightning.',
                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier', fontSize: 12),
              ),
              SizedBox(height: 16),
              Text(
                'Would you like to add a mint now?',
                style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
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

  // If mints are available, show the lightning receive dialog
  final amountController = TextEditingController();

  // Parse mint strings to get display names
  final mintList = mints.map((mint) {
    // Format: "mint_url:unit"
    final lastColonIndex = mint.lastIndexOf(':');
    if (lastColonIndex != -1) {
      return mint.substring(0, lastColonIndex);
    }
    return mint;
  }).toList();

  // Default selected mint (first one)
  String selectedMint = mintList.first;

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Receive via Lightning',
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
                    'Select Mint:',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00FF00)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      value: selectedMint,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FF00)),
                      hint: const Text(
                        'Default Mint',
                        style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                      ),
                      items: mintList.asMap().entries.map((entry) {
                        final mint = entry.value;
                        return DropdownMenuItem<String>(
                          value: mint,
                          child: Text(
                            mint,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'Courier',
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMint = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter amount to receive:',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount in sats',
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
                  const SizedBox(height: 12),
                  const Text(
                    'This will create a lightning invoice that you can pay to receive ecash tokens.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
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
                onPressed: () async {
                  final amountText = amountController.text.trim();

                  if (amountText.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter an amount',
                          style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
                        ),
                        backgroundColor: Color(0xFF1A1A1A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final amount = int.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid amount',
                          style: TextStyle(color: Color(0xFFFF6B6B), fontFamily: 'Courier'),
                        ),
                        backgroundColor: Color(0xFF1A1A1A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  onCreateInvoice(amount, selectedMint);
                },
                child: const Text(
                  'Create Invoice',
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

