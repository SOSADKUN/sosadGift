import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_intro_overlay.dart';

// '#' wall, '.' path, 'S' start, 'G' goal. Every variant shares the same
// size and the same S/G corners, so swapping layouts mid-game never strands
// the player or the goal on a wall.
const _mazeVariants = [
  [
    '###############',
    '#S....#.......#',
    '#####.#.#.###.#',
    '#.....#.#...#.#',
    '#.#####.###.###',
    '#.#.......#...#',
    '#.###.#####.#.#',
    '#...#.#...#.#.#',
    '###.###.#.###.#',
    '#.#.#...#...#.#',
    '#.#.#.#####.#.#',
    '#.....#......G#',
    '###############',
  ],
  [
    '###############',
    '#S#...#.#.....#',
    '#.#.#.#.#.###.#',
    '#...#.#.....#.#',
    '#####.#.#####.#',
    '#...#.#.#.#...#',
    '#.###.#.#.#.#.#',
    '#.#...#...#.#.#',
    '#.#.#######.#.#',
    '#.#.#.......#.#',
    '#.#.###.#####.#',
    '#.......#....G#',
    '###############',
  ],
  [
    '###############',
    '#S..#.......#.#',
    '###.#.###.#.#.#',
    '#.#.#...#.#...#',
    '#.#.#####.#####',
    '#...#...#.....#',
    '#.###.#.#.###.#',
    '#.#...#.#.#...#',
    '#.#.###.###.#.#',
    '#...#.#.#...#.#',
    '#####.#.#.###.#',
    '#.........#..G#',
    '###############',
  ],
];

class _Point {
  final int row;
  final int col;
  const _Point(this.row, this.col);
}

/// Which way the walking sprite is currently turned to face.
enum _Facing { up, down, left, right }

/// Grid maze: guide the character through the maze to the heart using the
/// on-screen arrows before the clock runs out. The heart makes a run for it
/// once, fleeing back to the start the first time you get close.
class GameThreeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;

  const GameThreeScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameThreeScreen> createState() => _GameThreeScreenState();
}

class _GameThreeScreenState extends State<GameThreeScreen> {
  static const _timeLimit = 90;
  static const _playerAsset = 'assets/photos/game3_move.gif';
  static const _goalAsset = 'assets/photos/game3_1.gif';
  static const _successAsset = 'assets/photos/game3_success.gif';

  final _rnd = Random();
  late final int _rows = _mazeVariants.first.length;
  late final int _cols = _mazeVariants.first[0].length;
  late final _Point _start = _findChar(_mazeVariants.first, 'S');
  late final _Point _goal = _findChar(_mazeVariants.first, 'G');
  late List<String> _mazeRows;

  int _playerRow = 0;
  int _playerCol = 0;
  // The sprite's native artwork faces left, so that's the unrotated pose.
  _Facing _facing = _Facing.left;
  late _Point _currentGoal;
  bool _goalFled = false;
  int _secondsLeft = _timeLimit;
  Timer? _clock;
  Timer? _messageTimer;
  String? _message;
  bool _finished = false;
  bool _won = false;
  bool _claimed = false;
  late bool _introDone;

  _Point _findChar(List<String> maze, String char) {
    for (int r = 0; r < maze.length; r++) {
      final c = maze[r].indexOf(char);
      if (c != -1) return _Point(r, c);
    }
    return const _Point(1, 1);
  }

  /// A different maze layout than the one currently shown.
  List<String> _pickDifferentMaze() {
    final others = _mazeVariants.where((m) => m != _mazeRows).toList();
    return others[_rnd.nextInt(others.length)];
  }

  bool _isWall(int row, int col) {
    if (row < 0 || row >= _rows || col < 0 || col >= _cols) return true;
    return _mazeRows[row][col] == '#';
  }

  @override
  void initState() {
    super.initState();
    _introDone = !widget.showIntro;
    _resetLevelState();
    if (_introDone) _startClock();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    _startClock();
  }

  void _resetLevelState() {
    _mazeRows = _mazeVariants.first;
    _playerRow = _start.row;
    _playerCol = _start.col;
    _facing = _Facing.left;
    _currentGoal = _goal;
    _goalFled = false;
    _secondsLeft = _timeLimit;
    _message = null;
    _finished = false;
    _won = false;
    _claimed = false;
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _fail();
    });
  }

  bool _isAdjacentToCurrentGoal() {
    final dr = (_playerRow - _currentGoal.row).abs();
    final dc = (_playerCol - _currentGoal.col).abs();
    return dr + dc == 1;
  }

  _Facing _facingFor(int dRow, int dCol) {
    if (dCol == 1) return _Facing.right;
    if (dCol == -1) return _Facing.left;
    if (dRow == -1) return _Facing.up;
    return _Facing.down;
  }

  void _move(int dRow, int dCol) {
    if (_finished) return;
    final newRow = _playerRow + dRow;
    final newCol = _playerCol + dCol;
    final facing = _facingFor(dRow, dCol);
    if (_isWall(newRow, newCol)) {
      setState(() => _facing = facing);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _playerRow = newRow;
      _playerCol = newCol;
      _facing = facing;
    });
    if (_playerRow == _currentGoal.row && _playerCol == _currentGoal.col) {
      _levelClear();
      return;
    }
    if (!_goalFled && _isAdjacentToCurrentGoal()) {
      _fleeGoal();
    }
  }

  void _fleeGoal() {
    HapticFeedback.heavyImpact();
    _messageTimer?.cancel();
    setState(() {
      _goalFled = true;
      _mazeRows = _pickDifferentMaze();
      // Drop the player back in at the same corner the new maze's goal
      // sits in, so they re-enter through a spot that's always open.
      _playerRow = _goal.row;
      _playerCol = _goal.col;
      _facing = _Facing.left;
      _currentGoal = _start;
      _message = '它跑掉啦！迷宫也变了，追回起点抓住它～';
    });
    _messageTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_finished) setState(() => _message = null);
    });
  }

  void _fail() {
    _finished = true;
    _clock?.cancel();
    setState(() => _message = '时间到啦，再试一次！');
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onLose();
    });
  }

  void _levelClear() {
    _finished = true;
    _won = true;
    _clock?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _message = null);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  Widget _arrowButton(IconData icon, int dRow, int dCol) {
    return GestureDetector(
      onTap: () => _move(dRow, dCol),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  /// The sprite's artwork faces left by default, so right needs a
  /// horizontal flip, and up/down are faked with a 90° rotation.
  Widget _playerSprite(double cell) {
    double angle;
    bool flip;
    switch (_facing) {
      case _Facing.left:
        angle = 0;
        flip = false;
        break;
      case _Facing.right:
        angle = 0;
        flip = true;
        break;
      case _Facing.up:
        angle = pi / 2;
        flip = false;
        break;
      case _Facing.down:
        angle = -pi / 2;
        flip = false;
        break;
    }
    return Padding(
      padding: EdgeInsets.all(cell * 0.1),
      child: AnimatedRotation(
        turns: angle / (2 * pi),
        duration: const Duration(milliseconds: 160),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
          child: Image.asset(
            _playerAsset,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameBackground(
          title: '迷宫大冒险',
          level: 1,
          levelCount: 1,
          backgroundImage: 'assets/photos/game3.png',
          child: Column(
            children: [
              const SizedBox(height: 6),
              Text(
                '⏱ $_secondsLeft s',
                style: TextStyle(
                  color: _secondsLeft <= 10 ? Colors.pinkAccent : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 6),
                Text(
                  _message!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _cols / _rows,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final cell = box.maxWidth / _cols;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                for (int r = 0; r < _rows; r++)
                                  for (int c = 0; c < _cols; c++)
                                    if (_mazeRows[r][c] == '#')
                                      Positioned(
                                        left: c * cell,
                                        top: r * cell,
                                        width: cell,
                                        height: cell,
                                        child: Container(
                                          margin: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8D6748),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  left: _currentGoal.col * cell,
                                  top: _currentGoal.row * cell,
                                  width: cell,
                                  height: cell,
                                  child: Padding(
                                    padding: EdgeInsets.all(cell * 0.1),
                                    child: Image.asset(
                                      _goalAsset,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOut,
                                  left: _playerCol * cell,
                                  top: _playerRow * cell,
                                  width: cell,
                                  height: cell,
                                  child: _playerSprite(cell),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _arrowButton(Icons.keyboard_arrow_up, -1, 0),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _arrowButton(Icons.keyboard_arrow_left, 0, -1),
                        const SizedBox(width: 40),
                        _arrowButton(Icons.keyboard_arrow_right, 0, 1),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _arrowButton(Icons.keyboard_arrow_down, 1, 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_won)
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      _successAsset,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '成功找到布布啦！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '获得一把钥匙 🔑',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (_claimed) return;
                      _claimed = true;
                      widget.onComplete();
                    },
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
        if (!_introDone)
          GameIntroOverlay(
            title: '迷宫大冒险',
            instructionText:
                '用下方的箭头带小鸡走出迷宫\n快到爱心时它会跑回起点，迷宫也会变新哦，别灰心追上去～\n时间限制 $_timeLimit 秒，加油哦～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
