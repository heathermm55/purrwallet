import 'package:flutter/material.dart';
import 'package:rust_plugin/src/rust/api/cashu.dart';
import 'mint_info_page.dart';

/// Mint detail management page with comprehensive mint operations
class MintDetailPage extends StatefulWidget {
  final String mintUrl;
  final String unit;
  
  const MintDetailPage({
    super.key,
    required this.mintUrl,
    required this.unit,
  });

  @override
  State<MintDetailPage> createState() => _MintDetailPageState();
}

class _MintDetailPageState extends State<MintDetailPage> {
  String? customName;
  bool isDefaultMint = false;
  String? mintInfo;
  bool isLoading = true;

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
        title: Text(
          customName ?? 'Mint Management',
          style: const TextStyle(
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
            icon: const Icon(Icons.more_vert, color: Color(0xFF00FF00)),
            onPressed: _showMintOptions,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralSection(),
                  const SizedBox(height: 16),
                  _buildFundsSection(),
                  const SizedBox(height: 16),
                  _buildDangerZoneSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildSection(
      title: 'GENERAL',
      children: [
        _buildInfoRow('Mint', widget.mintUrl),
        _buildInfoRow('Unit', widget.unit.toUpperCase()),
        _buildInfoRow('Balance', 'Loading...'), // TODO: Get actual balance
        _buildActionRow(
          'Show QR code',
          icon: Icons.qr_code,
          onTap: _showQRCode,
        ),
        _buildActionRow(
          'Custom name',
          trailing: Text(
            customName ?? 'Name',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
            ),
          ),
          onTap: _editCustomName,
        ),
        _buildSwitchRow(
          'Set as Default mint',
          value: isDefaultMint,
          onChanged: (value) {
            setState(() {
              isDefaultMint = value;
            });
            // TODO: Save default mint preference
          },
        ),
        _buildActionRow(
          'More info',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MintInfoPage(
                  mintUrl: widget.mintUrl,
                  unit: widget.unit,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFundsSection() {
    return _buildSection(
      title: 'FUNDS',
      children: [
        _buildActionRow(
          'Backup funds',
          icon: Icons.backup,
          onTap: _backupFunds,
        ),
        _buildActionRow(
          'Restore funds',
          icon: Icons.restore,
          onTap: _restoreFunds,
        ),
        _buildActionRow(
          'Mint tokens',
          icon: Icons.add_circle,
          onTap: _mintTokens,
        ),
        _buildActionRow(
          'Send tokens',
          icon: Icons.send,
          onTap: _sendTokens,
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return _buildSection(
      title: 'DANGER ZONE',
      titleColor: const Color(0xFFFF6B6B),
      children: [
        _buildActionRow(
          'Check proofs',
          icon: Icons.verified_user,
          textColor: const Color(0xFFFF6B6B),
          onTap: _checkProofs,
        ),
        _buildActionRow(
          'Delete mint',
          icon: Icons.delete_forever,
          textColor: const Color(0xFFFF6B6B),
          onTap: _deleteMint,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color titleColor = const Color(0xFF00FF00),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String label, {
    IconData? icon,
    Widget? trailing,
    Color textColor = const Color(0xFF00FF00),
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(icon, color: textColor, size: 20)
            : null,
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF666666),
              size: 16,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchRow(
    String label, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00FF00),
          activeTrackColor: const Color(0xFF00FF00).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF333333),
        ),
      ),
    );
  }

  void _loadMintInfo() async {
    try {
      // TODO: Load mint info using NUT-06 specification
      // This would involve calling the mint's /info endpoint
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      
      setState(() {
        isLoading = false;
        mintInfo = 'Mint info loaded successfully';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load mint info: $e'),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Mint QR Code',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'QR Code\nPlaceholder',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.mintUrl,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomName() {
    final controller = TextEditingController(text: customName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Custom Name',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
          decoration: const InputDecoration(
            hintText: 'Enter custom name',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              setState(() {
                customName = controller.text.trim().isEmpty ? null : controller.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _backupFunds() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup funds functionality coming soon'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }

  void _restoreFunds() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restore funds functionality coming soon'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }

  void _mintTokens() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mint tokens functionality coming soon'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }

  void _sendTokens() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Send tokens functionality coming soon'),
        backgroundColor: Color(0xFF1A1A1A),
      ),
    );
  }

  void _checkProofs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Check Proofs',
          style: TextStyle(
            color: Color(0xFFFF6B6B),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will verify all cryptographic proofs for this mint. This operation may take some time.',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking proofs...'),
                  backgroundColor: Color(0xFF1A1A1A),
                ),
              );
            },
            child: const Text(
              'Check',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Mint',
          style: TextStyle(
            color: Color(0xFFFF6B6B),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this mint?',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mintUrl,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This action cannot be undone!',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              Navigator.of(context).pop();
              _confirmDeleteMint();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMint() async {
    try {
      final result = removeMint(mintUrl: widget.mintUrl, unit: widget.unit);
      print('Delete mint result: $result');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mint deleted successfully'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
        Navigator.of(context).pop(); // Return to mints list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete mint: $e'),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  void _showMintOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFF00FF00)),
              title: const Text(
                'Refresh',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _loadMintInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF00FF00)),
              title: const Text(
                'Share',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
