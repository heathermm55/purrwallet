import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';

/// Mint info page displaying detailed mint information according to NUT-06
class MintInfoPage extends StatefulWidget {
  final String mintUrl;
  final String unit;
  
  const MintInfoPage({
    super.key,
    required this.mintUrl,
    required this.unit,
  });

  @override
  State<MintInfoPage> createState() => _MintInfoPageState();
}

class _MintInfoPageState extends State<MintInfoPage> {
  bool isLoading = true;
  MintInfo? mintInfo;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMintInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Mint info',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FF00)),
            onPressed: _loadMintInfo,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
              ),
            )
          : error != null
              ? _buildErrorState()
              : _buildMintInfoContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFFF6B6B),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load mint info',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontFamily: 'Courier',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMintInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF00),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMintInfoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMintIdentificationCard(),
          const SizedBox(height: 16),
          if (_hasContactInfo()) ...[
            _buildContactCard(),
            const SizedBox(height: 16),
          ],
          if (_hasSupportedNuts()) ...[
            _buildSupportedNutsCard(),
            const SizedBox(height: 16),
          ],
          if (_hasPublicKey()) ...[
            _buildPublicKeyCard(),
            const SizedBox(height: 16),
          ],
          if (_hasAdditionalInfo()) ...[
            _buildAdditionalInfoCard(),
          ],
        ],
      ),
    );
  }

  bool _hasContactInfo() {
    return mintInfo?.contact != null && mintInfo!.contact!.isNotEmpty;
  }

  bool _hasSupportedNuts() {
    return mintInfo?.nuts != null && mintInfo!.nuts!.isNotEmpty;
  }

  bool _hasPublicKey() {
    return mintInfo?.publicKey != null && mintInfo!.publicKey!.isNotEmpty;
  }

  bool _hasAdditionalInfo() {
    return mintInfo?.additionalInfo != null && mintInfo!.additionalInfo!.isNotEmpty;
  }

  Widget _buildMintIdentificationCard() {
    return _buildInfoCard(
      title: mintInfo?.name ?? 'Unknown Mint',
      subtitle: 'Version: ${mintInfo?.version ?? 'Unknown'}',
      description: mintInfo?.description ?? 'No description available',
    );
  }

  Widget _buildContactCard() {
    return _buildSectionCard(
      title: 'Contact',
      children: [
        if (mintInfo?.contact != null)
          for (final contact in mintInfo!.contact!)
            _buildContactItem(
              icon: _getContactIcon(contact.method),
              label: contact.method,
              value: contact.info,
              isLongText: false,
            ),
      ],
    );
  }

  IconData _getContactIcon(String method) {
    switch (method.toLowerCase()) {
      case 'email':
        return Icons.email;
      case 'twitter':
        return Icons.alternate_email;
      case 'nostr':
        return Icons.account_circle;
      default:
        return Icons.contact_mail;
    }
  }

  Widget _buildSupportedNutsCard() {
    final supportedNuts = mintInfo?.nuts ?? [];
    return _buildSectionCard(
      title: 'Supported NUTs',
      children: [
        if (supportedNuts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supportedNuts.map<Widget>((nut) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00FF00)),
                ),
                child: Text(
                  nut.startsWith('NUT-') ? nut : 'NUT-$nut',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          )
        else
          const Text(
            'No supported NUTs information available',
            style: TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
            ),
          ),
      ],
    );
  }

  Widget _buildPublicKeyCard() {
    return _buildSectionCard(
      title: 'Public key',
      children: [
        _buildLongTextItem(
          mintInfo?.publicKey ?? 'No public key available',
          copyable: true,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    return _buildSectionCard(
      title: 'Additional information',
      children: [
        _buildLongTextItem(
          mintInfo?.additionalInfo ?? 'No additional information available',
          copyable: true,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'Courier',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label $value',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontSize: 14,
                  ),
                ),
                if (isLongText)
                  const SizedBox(height: 4),
                if (isLongText)
                  GestureDetector(
                    onTap: () => _copyToClipboard(value),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A0D),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00FF00)),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontFamily: 'Courier',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongTextItem(String text, {bool copyable = false}) {
    return GestureDetector(
      onTap: copyable ? () => _copyToClipboard(text) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A0D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00FF00)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
            if (copyable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.copy,
                    color: Color(0xFF666666),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Tap to copy',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadMintInfo() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Fetch mint info using Rust API (NUT-06)
      final mintInfoData = await getMintInfo(
        mintUrl: widget.mintUrl,
      );
      
      setState(() {
        mintInfo = mintInfoData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Copied to clipboard',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
