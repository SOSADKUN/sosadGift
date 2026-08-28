import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gift/controllers/ticket_service.dart';
import 'scan_success_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _handling = false;
  bool _checkingPermission = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _checkingPermission = false;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _handling = true);

    final result = await TicketService.redeemTicket(code);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ScanSuccessPage(alreadyUsed: result == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan pass')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_checkingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera permission is required to scan passes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final status = await Permission.camera.request();
                  if (status.isPermanentlyDenied) {
                    openAppSettings();
                  } else if (status.isGranted) {
                    setState(() => _permissionGranted = true);
                  }
                },
                child: const Text('Grant camera access'),
              ),
            ],
          ),
        ),
      );
    }

    return MobileScanner(
      onDetect: _onDetect,
      errorBuilder: (context, error, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Camera error: ${error.errorCode}\n${error.errorDetails?.message ?? ''}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}