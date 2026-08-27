import 'package:flutter/material.dart';

class ScanSuccessPage extends StatelessWidget {
  final bool alreadyUsed;
  const ScanSuccessPage({super.key, required this.alreadyUsed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              alreadyUsed ? Icons.block : Icons.check_circle,
              color: alreadyUsed ? Colors.grey : Colors.greenAccent,
              size: 96,
            ),
            const SizedBox(height: 16),
            Text(
              alreadyUsed ? 'Already redeemed' : 'Success — checked in',
              style: TextStyle(
                color: alreadyUsed ? Colors.grey : Colors.greenAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}