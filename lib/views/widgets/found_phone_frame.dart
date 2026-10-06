import 'package:flutter/material.dart';

/// A physical bezel around both the lock screen and the recovered conversation.
class FoundPhoneFrame extends StatelessWidget {
  const FoundPhoneFrame({super.key, required this.child, this.dark = false});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: const Color(0xFF14141C),
      borderRadius: BorderRadius.circular(42),
      border: Border.all(color: const Color(0xFF79747F), width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 35, offset: Offset(0, 18)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(33),
      child: ColoredBox(
        color: dark ? const Color(0xFF211B32) : const Color(0xFFF1EDE8),
        child: Column(
          children: [
            SizedBox(
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 95,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0B10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    child: Row(
                      children: [
                        Text(
                          '9:14',
                          style: TextStyle(
                            color: dark ? Colors.white70 : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 13,
                          color: dark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.battery_full,
                          size: 15,
                          color: dark ? Colors.white70 : Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white60 : Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
