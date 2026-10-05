import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/treasure_hunt_config.dart';

class TreasureScannerScreen extends StatefulWidget {
  const TreasureScannerScreen({super.key});

  @override
  State<TreasureScannerScreen> createState() => _TreasureScannerScreenState();
}

class _TreasureScannerScreenState extends State<TreasureScannerScreen> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _handled = false;
  String _hint = '对准你在现实中找到的最后一个二维码';

  void _detect(BarcodeCapture capture) {
    if (_handled) return;
    if (!capture.barcodes.any(
      (code) => TreasureHuntConfig.acceptsQr(code.rawValue),
    )) {
      setState(() => _hint = '这不是最后的线索，再找找看。');
      return;
    }
    _handled = true;
    _controller.stop();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('扫描最后的线索')),
    body: Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: _detect,
            errorBuilder: (_, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? '请在系统设置中允许相机权限，然后重新打开扫描。'
                          : '相机暂时无法使用，请返回聊天后重试。',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: openAppSettings,
                      child: const Text('打开系统设置'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.all(24), child: Text(_hint)),
        ),
      ],
    ),
  );
}
