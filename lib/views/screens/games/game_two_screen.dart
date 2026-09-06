import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_intro_overlay.dart';

enum _Element { metal, wood, water, fire, earth }

// Wu Xing overcoming cycle: 火克金, 金克木, 木克土, 土克水, 水克火.
// Value = the element that beats the key element.
const Map<_Element, _Element> _counterOf = {
  _Element.metal: _Element.fire,
  _Element.wood: _Element.metal,
  _Element.earth: _Element.wood,
  _Element.water: _Element.earth,
  _Element.fire: _Element.water,
};

const Map<_Element, String> _char = {
  _Element.metal: '金',
  _Element.wood: '木',
  _Element.water: '水',
  _Element.fire: '火',
  _Element.earth: '土',
};

const Map<_Element, String> _emoji = {
  _Element.metal: '⚙️',
  _Element.wood: '🌳',
  _Element.water: '💧',
  _Element.fire: '🔥',
  _Element.earth: '🪨',
};

const Map<_Element, List<String>> _aliases = {
  _Element.metal: ['金', 'jin', 'metal', 'gold'],
  _Element.wood: ['木', 'mu', 'wood'],
  _Element.water: ['水', 'shui', 'water'],
  _Element.fire: ['火', 'huo', 'fire'],
  _Element.earth: ['土', 'tu', 'earth', 'soil'],
};

class _LevelConfig {
  final int bossHp;
  final int hitDamage;
  final int wrongPenalty;
  const _LevelConfig({
    required this.bossHp,
    required this.hitDamage,
    required this.wrongPenalty,
  });
}

/// Boss battle: the boss shows an element, type the element that overcomes it
/// (五行相克) and attack. Get it wrong and the boss hits back.
class GameTwoScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;

  const GameTwoScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameTwoScreen> createState() => _GameTwoScreenState();
}

class _GameTwoScreenState extends State<GameTwoScreen> {
  static const _playerMaxHp = 100;
  static const _levels = [
    _LevelConfig(bossHp: 30, hitDamage: 10, wrongPenalty: 10),
    _LevelConfig(bossHp: 50, hitDamage: 10, wrongPenalty: 15),
    _LevelConfig(bossHp: 70, hitDamage: 10, wrongPenalty: 20),
  ];

  final _rnd = Random();
  final _controller = TextEditingController();
  int _levelIndex = 0;
  int _bossHp = 0;
  int _playerHp = _playerMaxHp;
  _Element _bossElement = _Element.fire;
  String? _message;
  bool _finished = false;
  late bool _introDone;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _introDone = !widget.showIntro;
    if (_introDone) _startLevel();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    _startLevel();
  }

  void _startLevel() {
    _bossHp = _level.bossHp;
    _playerHp = _playerMaxHp;
    _bossElement = _Element.values[_rnd.nextInt(_Element.values.length)];
    _message = null;
    _finished = false;
    _controller.clear();
  }

  _Element? _matchElement(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final e in _Element.values) {
      for (final alias in _aliases[e]!) {
        final a = alias.toLowerCase();
        if (normalized == a || normalized.contains(a)) return e;
      }
    }
    return null;
  }

  _Element _nextBossElement(_Element current) {
    _Element next;
    do {
      next = _Element.values[_rnd.nextInt(_Element.values.length)];
    } while (next == current);
    return next;
  }

  void _attack() {
    if (_finished) return;
    final input = _controller.text;
    _controller.clear();
    if (input.trim().isEmpty) return;

    final matched = _matchElement(input);
    final correct = matched != null && matched == _counterOf[_bossElement];

    setState(() {
      if (correct) {
        _bossHp -= _level.hitDamage;
        _message = '命中！${_char[_bossElement]}${_emoji[_bossElement]} 被克制啦！';
      } else if (matched == null) {
        _playerHp -= _level.wrongPenalty;
        _message = '没有识别到这个元素，被反击了！';
      } else {
        _playerHp -= _level.wrongPenalty;
        _message = '元素不对，被反击了！';
      }
    });

    if (_bossHp <= 0) {
      _levelClear();
      return;
    }
    if (_playerHp <= 0) {
      _fail();
      return;
    }
    if (correct) {
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _finished) return;
        setState(() {
          _bossElement = _nextBossElement(_bossElement);
          _message = null;
        });
      });
    }
  }

  void _fail() {
    _finished = true;
    setState(() => _message = '再试一次！');
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onLose();
    });
  }

  void _levelClear() {
    _finished = true;
    if (_levelIndex >= _levels.length - 1) {
      setState(() => _message = '通关啦！🎉');
      Timer(const Duration(milliseconds: 700), widget.onComplete);
    } else {
      setState(() => _message = 'Level ${_levelIndex + 1} 完成！');
      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _levelIndex++);
        _startLevel();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _hpBar(int hp, int maxHp, Color color) {
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 14,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameBackground(
          title: '元素大作战',
          level: _levelIndex + 1,
          levelCount: _levels.length,
          backgroundImage: 'assets/photos/game2.png',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(_emoji[_bossElement]!, style: const TextStyle(fontSize: 56)),
                Text(
                  'Boss: ${_char[_bossElement]} ${_emoji[_bossElement]}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                _hpBar(_bossHp, _level.bossHp, Colors.redAccent),
                Text('$_bossHp / ${_level.bossHp}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                const Text(
                  '提示：金克木 · 木克土 · 土克水 · 水克火 · 火克金',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_finished,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _attack(),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: '写下你的技能，如：火',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _finished ? null : _attack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.brown[800],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('攻击',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _hpBar(_playerHp, _playerMaxHp, Colors.greenAccent),
                Text('我方 HP: $_playerHp / $_playerMaxHp',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (!_introDone)
          GameIntroOverlay(
            title: '元素大作战',
            instructionText:
                '元素大作战～ Boss 会显示一个元素，请写出能克制它的元素来攻击\n（金克木 木克土 土克水 水克火 火克金）\n写错会被反击哦～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
