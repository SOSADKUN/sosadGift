import 'dart:math';
import 'package:flutter/material.dart';

/// Simple memory-match game: flip 2 cards at a time, find all pairs.
/// Swap the emoji list for photo assets later if you want it more personal.
class GameTwoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GameTwoScreen({super.key, required this.onComplete});

  @override
  State<GameTwoScreen> createState() => _GameTwoScreenState();
}

class _GameTwoScreenState extends State<GameTwoScreen> {
  static const _symbols = ['🎂', '🎁', '💌', '⭐', '🎮', '🧸'];
  late List<String> _cards;
  final Set<int> _flipped = {};
  final Set<int> _matched = {};
  int? _firstIndex;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _cards = [..._symbols, ..._symbols]..shuffle(Random());
  }

  void _onTap(int index) {
    if (_busy || _flipped.contains(index) || _matched.contains(index)) return;

    setState(() => _flipped.add(index));

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;

    if (_cards[first] == _cards[index]) {
      _matched.addAll([first, index]);
      if (_matched.length == _cards.length) {
        Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
      }
    } else {
      _busy = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        setState(() {
          _flipped.remove(first);
          _flipped.remove(index);
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, i) {
          final revealed = _flipped.contains(i) || _matched.contains(i);
          return GestureDetector(
            onTap: () => _onTap(i),
            child: Container(
              decoration: BoxDecoration(
                color: revealed ? Colors.pink[100] : Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                revealed ? _cards[i] : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}