import 'package:flutter/material.dart';
import 'qr_display_page.dart';
import 'qr_scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Happy Birthday 🎂')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrDisplayPage()),
                );
              },
              child: const Text('Show QR Pass'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScannerPage()),
                );
              },
              child: const Text('Scan QR Pass'),
            ),
          ],
        ),
      ),
    );
  }
}