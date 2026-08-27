import 'dart:math';

import 'package:flutter/material.dart';

class PinLoginPage extends StatefulWidget {
  const PinLoginPage({super.key});

  @override
  State<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends State<PinLoginPage>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];

  late AnimationController _animationController;

  final Random _random = Random();

  final List<_FloatingHeart> _hearts = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    for (int i = 0; i < 18; i++) {
      _hearts.add(
        _FloatingHeart(
          left: _random.nextDouble(),
          size: 15 + _random.nextDouble() * 20,
          delay: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pressNumber(String number) {
    if (_pin.length >= 6) return;

    setState(() {
      _pin.add(number);
    });
  }

  void _deleteNumber() {
    if (_pin.isEmpty) return;

    setState(() {
      _pin.removeLast();
    });
  }

  void _enter() {
    if (_pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 6-digit PIN 💗'),
        ),
      );
      return;
    }

    // We will connect this to Supabase PIN verification next.
    debugPrint('PIN entered: ${_pin.join()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              _buildBackground(),
              _buildFloatingHearts(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        _buildLogo(),

                        const SizedBox(height: 22),

                        const Text(
                          'Your little surprise is waiting 💗',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 35),

                        _buildPinIndicator(),

                        const SizedBox(height: 30),

                        _buildKeypad(),

                        const SizedBox(height: 22),

                        _buildEnterButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB6D5),
            Color(0xFFFF8FBD),
            Color(0xFFFF6FAE),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.25),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🎁',
          style: TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) {
          final filled = index < _pin.length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: filled ? 15 : 13,
            height: filled ? 15 : 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? Colors.white
                  : Colors.white.withOpacity(0.35),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '⌫',
      '0',
      '',
    ];

    return SizedBox(
      width: 300,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];

          if (key.isEmpty) {
            return const SizedBox();
          }

          return _buildKey(
            key,
            onTap: () {
              if (key == '⌫') {
                _deleteNumber();
              } else {
                _pressNumber(key);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildKey(
    String text, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: text == '⌫' ? 24 : 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterButton() {
    return SizedBox(
      width: 300,
      height: 56,
      child: ElevatedButton(
        onPressed: _enter,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.pinkAccent,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'ENTER  💗',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHearts() {
    return IgnorePointer(
      child: Stack(
        children: _hearts.map((heart) {
          final progress =
              (_animationController.value + heart.delay) % 1.0;

          final screenHeight =
              MediaQuery.of(context).size.height;

          final screenWidth =
              MediaQuery.of(context).size.width;

          final top =
              screenHeight + 40 - (screenHeight + 80) * progress;

          final left = screenWidth * heart.left;

          final opacity = sin(progress * pi);

          return Positioned(
            left: left,
            top: top,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(
                '♥',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: heart.size,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FloatingHeart {
  final double left;
  final double size;
  final double delay;

  _FloatingHeart({
    required this.left,
    required this.size,
    required this.delay,
  });
}