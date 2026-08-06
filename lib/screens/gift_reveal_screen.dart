import 'package:flutter/material.dart';

class GiftRevealScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GiftRevealScreen({super.key, required this.onComplete});

  @override
  State<GiftRevealScreen> createState() => _GiftRevealScreenState();
}

class _GiftRevealScreenState extends State<GiftRevealScreen> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _opened
            ? Padding(
                key: const ValueKey('voucher'),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TODO: replace with your actual gift voucher design/asset
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Text(
                        '🎟️ 礼物券\n\nTODO: 写上你想给的礼物内容',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: widget.onComplete,
                      child: const Text('继续'),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                key: const ValueKey('box'),
                onTap: () => setState(() => _opened = true),
                child: const Text('🎁', style: TextStyle(fontSize: 100)),
              ),
      ),
    );
  }
}