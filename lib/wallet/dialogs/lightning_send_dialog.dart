import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'dart:convert';

/// Invoice details model
class InvoiceDetails {
  final int amountSats;
  final String description;
  
  InvoiceDetails({
    required this.amountSats,
    required this.description,
  });
}

/// Show lightning send dialog
Future<void> showLightningSendDialog({
  required BuildContext context,
  required Function(String invoice) onPayInvoice,
  String? initialInvoice,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return _LightningSendDialogContent(
        onPayInvoice: onPayInvoice,
        initialInvoice: initialInvoice,
      );
    },
  );
}

class _LightningSendDialogContent extends StatefulWidget {
  final Function(String invoice) onPayInvoice;
  final String? initialInvoice;

  const _LightningSendDialogContent({
    required this.onPayInvoice,
    this.initialInvoice,
  });

  @override
  State<_LightningSendDialogContent> createState() => _LightningSendDialogContentState();
}

class _LightningSendDialogContentState extends State<_LightningSendDialogContent> {
  late TextEditingController _invoiceController;
  InvoiceDetails? _invoiceDetails;
  bool _isDecoding = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invoiceController = TextEditingController(text: widget.initialInvoice);
    if (widget.initialInvoice != null && widget.initialInvoice!.isNotEmpty) {
      _decodeInvoice(widget.initialInvoice!);
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _decodeInvoice(String invoice) async {
    if (invoice.isEmpty) {
      setState(() {
        _invoiceDetails = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isDecoding = true;
      _errorMessage = null;
    });

    try {
      final result = await decodeBolt11Invoice(invoice: invoice);
      final json = jsonDecode(result);
      
      setState(() {
        _invoiceDetails = InvoiceDetails(
          amountSats: json['amount_sats'] as int,
          description: json['description'] as String,
        );
        _isDecoding = false;
      });
    } catch (e) {
      setState(() {
        _invoiceDetails = null;
        _errorMessage = 'Invalid invoice: $e';
        _isDecoding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Send via Lightning',
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
              'Lightning Invoice:',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _invoiceController,
              style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Paste lightning invoice here...',
                hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier'),
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF00))),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00FF00)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00FF00)),
                ),
              ),
              onChanged: (value) {
                _decodeInvoice(value.trim());
              },
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
                        _invoiceController.text = clipboardData.text!;
                        _decodeInvoice(clipboardData.text!.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invoice pasted from clipboard',
                                style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
                              ),
                              backgroundColor: Color(0xFF1A1A1A),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
            
            // Show decoding indicator
            if (_isDecoding) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Decoding invoice...',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
            
            // Show error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF6B6B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontFamily: 'Courier',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Show decoded invoice details
            if (_invoiceDetails != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00FF00)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Details:',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount:',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontFamily: 'Courier',
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${_invoiceDetails!.amountSats} sats',
                          style: const TextStyle(
                            color: Color(0xFF00FF00),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_invoiceDetails!.description.isNotEmpty && 
                        _invoiceDetails!.description != 'No description') ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Description:',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _invoiceDetails!.description,
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'Courier',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!_isDecoding && _errorMessage == null) ...[
              const SizedBox(height: 16),
              const Text(
                'Enter a lightning invoice to see payment details.',
                style: TextStyle(color: Color(0xFF666666), fontFamily: 'Courier', fontSize: 10),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier'),
          ),
        ),
        TextButton(
          onPressed: _invoiceDetails != null
              ? () {
                  final invoice = _invoiceController.text.trim();
                  Navigator.of(context).pop();
                  widget.onPayInvoice(invoice);
                }
              : null,
          child: Text(
            _invoiceDetails != null 
                ? 'Pay ${_invoiceDetails!.amountSats} sats'
                : 'Pay Invoice',
            style: TextStyle(
              color: _invoiceDetails != null ? const Color(0xFF00FF00) : const Color(0xFF666666),
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
