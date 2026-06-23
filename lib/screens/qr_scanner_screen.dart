import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.onCodeScanned});

  final Future<void> Function(String rawValue)? onCodeScanned;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    autoZoom: true,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 700,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
    ],
  );
  final Map<String, DateTime> _recentScans = {};
  bool _isProcessing = false;
  String? _lastMessage;

  bool get _isUnsupportedWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      rawValue = value;
      break;
    }
    if (rawValue == null) return;

    final now = DateTime.now();
    final lastSeen = _recentScans[rawValue];
    if (lastSeen != null && now.difference(lastSeen).inSeconds < 4) return;
    _recentScans[rawValue] = now;

    if (widget.onCodeScanned == null) {
      Navigator.of(context).pop(rawValue);
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastMessage = 'جارى تسجيل الكود $rawValue...';
    });

    try {
      await widget.onCodeScanned!(rawValue);
      if (!mounted) return;
      setState(() => _lastMessage = 'تمت قراءة الكود $rawValue');
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastMessage = 'تعذر تسجيل الكود $rawValue');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تسجيل الكود: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('فحص QR الكارنيه'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: _isUnsupportedWindows
              ? null
              : [
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      if (state.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      final isOn = state.torchState == TorchState.on;
                      return IconButton(
                        tooltip: isOn ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
                        onPressed: _controller.toggleTorch,
                        icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'تبديل الكاميرا',
                    onPressed: _controller.switchCamera,
                    icon: const Icon(Icons.cameraswitch),
                  ),
                ],
        ),
        body: _isUnsupportedWindows
            ? const _UnsupportedCameraView()
            : Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleDetect,
                    onDetectError: (error, stackTrace) {
                      debugPrint('QR scanner error: $error');
                    },
                  ),
                  const _ScannerGuide(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      minimum: const EdgeInsets.all(20),
                      child: _ScannerStatus(
                        isProcessing: _isProcessing,
                        message: _lastMessage,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ScannerStatus extends StatelessWidget {
  const _ScannerStatus({required this.isProcessing, required this.message});

  final bool isProcessing;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              message ??
                  'اعرض الكارنيه أو الورقة أمام الكاميرا، وسيتم التقاط الرمز من أي مكان ظاهر في الصورة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedCameraView extends StatelessWidget {
  const _UnsupportedCameraView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 18),
              const Text(
                'كاميرا اللاب غير مدعومة في نسخة Windows الحالية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ماسح QR يعمل بالكاميرا على الهاتف. نسخة Windows من الحزمة المستخدمة لا تعرض كاميرا الجهاز.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerGuide extends StatelessWidget {
  const _ScannerGuide();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth * 0.82).clamp(260.0, 460.0);
          final height = (constraints.maxHeight * 0.52).clamp(260.0, 380.0);
          return Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.86),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'يلتقط الرمز من كل الصورة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
