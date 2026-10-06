import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _takingPhoto = false;
  String _hint = '对准你在现实中找到的最后一个二维码';

  void _detect(BarcodeCapture capture) {
    if (!mounted || _handled || _takingPhoto) return;
    _checkCapture(capture);
  }

  void _checkCapture(BarcodeCapture capture) {
    if (!mounted || _handled) return;
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

  Future<void> _takePhoto() async {
    if (_takingPhoto || _handled) return;
    setState(() => _takingPhoto = true);
    try {
      await _controller.stop();
      final photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || photo == null) return;
      final capture = await _controller.analyzeImage(
        photo.path,
        formats: [BarcodeFormat.qrCode],
      );
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) {
        setState(() => _hint = '照片里没有找到二维码，请对准后再拍一次。');
      } else {
        _checkCapture(capture);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hint = '拍照暂时无法使用，请检查相机权限后重试。');
      }
    } finally {
      if (mounted && !_handled) {
        try {
          await _controller.start();
        } catch (_) {
          if (mounted) {
            setState(() => _hint = '相机暂时无法使用，请返回后重试。');
          }
        }
        if (mounted) setState(() => _takingPhoto = false);
      }
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final frameSize = math.min(
                260.0,
                math.min(constraints.maxWidth, constraints.maxHeight) * 0.7,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
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
                              error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
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
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: frameSize,
                        height: frameSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(_hint, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _takingPhoto || _handled ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_takingPhoto ? '正在读取照片…' : '拍照'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
