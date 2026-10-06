import 'package:flutter/material.dart';

/// Victory waits for the player to collect the key before leaving the game.
class GameKeyRewardOverlay extends StatelessWidget {
  const GameKeyRewardOverlay({
    super.key,
    required this.message,
    required this.onClaim,
  });
  final String message;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x77000000)),
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xF22D223C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 52,
                  color: Color(0xFFFFBBD0),
                ),
                const SizedBox(height: 14),
                const Text(
                  '钥匙到手啦！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onClaim,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFBBD0),
                    foregroundColor: const Color(0xFF392239),
                  ),
                  child: const Text('领取钥匙，回到小屋'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
