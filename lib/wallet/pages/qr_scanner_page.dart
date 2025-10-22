import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR Scanner Page
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });
        
        // Return the scanned code and close the scanner
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF00)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Color(0xFF00FF00),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: const Color(0xFF00FF00),
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Color(0xFF00FF00)),
            onPressed: () {
              _controller.switchCamera();
              setState(() {
                _isFrontCamera = !_isFrontCamera;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning frame
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),
          
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00FF00)),
                  ),
                  child: const Text(
                    'Align QR code',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // Navigate back and trigger manual input
                    Navigator.of(context).pop('__MANUAL_INPUT__');
                  },
                  icon: const Icon(Icons.keyboard, color: Color(0xFF00FF00), size: 20),
                  label: const Text(
                    'Enter Manually',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
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
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw semi-transparent overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanArea)
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Draw corner markers
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    const double cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + scanAreaSize, top), Offset(left + scanAreaSize - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), Offset(left + scanAreaSize, top + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + scanAreaSize), Offset(left + cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), Offset(left, top + scanAreaSize - cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize), Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), cornerPaint);

    // Draw scanning line animation (optional)
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.5)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(left, top + scanAreaSize / 2),
      Offset(left + scanAreaSize, top + scanAreaSize / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

