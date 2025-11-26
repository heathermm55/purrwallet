import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

import 'add_mint_dialog.dart';

class P2pkSendRequest {
  const P2pkSendRequest({
    required this.amount,
    required this.memo,
    required this.mintUrl,
    required this.recipientPubKey,
    required this.additionalPubKeys,
    required this.refundPubKeys,
    required this.requiredSignatures,
    required this.refundRequiredSignatures,
    required this.locktimeSeconds,
    required this.sigFlag,
  });

  final String amount;
  final String memo;
  final String mintUrl;
  final String recipientPubKey;
  final List<String> additionalPubKeys;
  final List<String> refundPubKeys;
  final int? requiredSignatures;
  final int? refundRequiredSignatures;
  final int? locktimeSeconds;
  final String? sigFlag;
}

Future<void> showP2pkSendDialog({
  required BuildContext context,
  required void Function(P2pkSendRequest request) onCreateToken,
  required VoidCallback onRefresh,
}) async {
  List<String> mints = [];
  try {
    mints = await listMints();
  } catch (_) {}

  if (mints.isEmpty) {
    // Same UX as ecash dialog: ask user to add mint first
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
            'Please add a mint first before sending P2PK tokens.',
            style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                showAddMintDialog(context: context, onMintAdded: onRefresh);
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

  final parsedMints =
      mints.map((mint) {
        final parts = mint.split(':');
        if (parts.length >= 2) {
          return parts.sublist(0, parts.length - 1).join(':');
        }
        return mint;
      }).toList();

  final amountController = TextEditingController();
  final memoController = TextEditingController();
  final pubKeyController = TextEditingController();
  final additionalPubKeysController = TextEditingController();
  final refundPubKeysController = TextEditingController();
  final requiredSigsController = TextEditingController();
  final refundRequiredSigsController = TextEditingController();
  final locktimeController = TextEditingController();

  String selectedMint = parsedMints[0];
  String selectedMintFull = mints[0];
  bool showAdvanced = false;
  String selectedSigFlag = 'SIG_INPUTS';

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Send P2PK Token',
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
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                      ),
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
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add a note',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                      ),
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

                  const Text(
                    'Recipient public key (hex or npub):',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pubKeyController,
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      hintText: '02abc... or npub1...',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontFamily: 'Courier',
                      ),
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

                  TextButton.icon(
                    onPressed:
                        () => setState(() => showAdvanced = !showAdvanced),
                    icon: Icon(
                      showAdvanced ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF00FF00),
                    ),
                    label: Text(
                      showAdvanced
                          ? 'Hide advanced options'
                          : 'Show advanced options',
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  if (showAdvanced) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Additional recipient pubkeys (comma or space separated)',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: additionalPubKeysController,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Optional',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
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
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Refund pubkeys (comma or space separated)',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: refundPubKeysController,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Optional',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
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
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Required signatures',
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: requiredSigsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontFamily: 'Courier',
                                ),
                                decoration: const InputDecoration(
                                  hintText: '1',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF666666),
                                    fontFamily: 'Courier',
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Refund signatures',
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: refundRequiredSigsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontFamily: 'Courier',
                                ),
                                decoration: const InputDecoration(
                                  hintText: '1',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF666666),
                                    fontFamily: 'Courier',
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF00FF00),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Locktime (unix seconds)',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locktimeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Optional',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                        ),
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

                    const Text(
                      'Signature flag',
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
                        value: selectedSigFlag,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        underline: const SizedBox(),
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'SIG_INPUTS',
                            child: Text(
                              'SIG_INPUTS (default)',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'SIG_ALL',
                            child: Text(
                              'SIG_ALL',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedSigFlag = value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCreateToken(
                    P2pkSendRequest(
                      amount: amountController.text,
                      memo: memoController.text,
                      mintUrl: selectedMintFull,
                      recipientPubKey: pubKeyController.text,
                      additionalPubKeys: _parsePubKeyInput(
                        additionalPubKeysController.text,
                      ),
                      refundPubKeys: _parsePubKeyInput(
                        refundPubKeysController.text,
                      ),
                      requiredSignatures: _parseOptionalInt(
                        requiredSigsController.text,
                      ),
                      refundRequiredSignatures: _parseOptionalInt(
                        refundRequiredSigsController.text,
                      ),
                      locktimeSeconds: _parseOptionalInt(
                        locktimeController.text,
                      ),
                      sigFlag: showAdvanced ? selectedSigFlag : null,
                    ),
                  );
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

List<String> _parsePubKeyInput(String raw) {
  if (raw.trim().isEmpty) {
    return const [];
  }

  final parts = raw.split(RegExp(r'[,\s]+'));
  return parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet()
      .toList();
}

int? _parseOptionalInt(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  return int.tryParse(raw.trim());
}
