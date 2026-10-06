import 'dart:async';
import '../../../games/game_timer.dart';
import 'package:flame/game.dart';
import '../../../games/maze_game.dart';
import '../../../games/maze_layouts.dart';
import '../../../games/maze_bomb_puzzle.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/maze_joystick.dart';
import '../../widgets/game_failure_overlay.dart';
import '../../widgets/game_intro_overlay.dart';
import '../../widgets/game_key_reward_overlay.dart';

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

class _GameThreeScreenState extends State<GameThreeScreen>
    with WidgetsBindingObserver {
  static const _timeLimit = 90;

  late final MazeGame _field;
  Timer? _holdTimer;
  bool _paused = false;
  bool _fieldReady = false;
  final _rnd = Random();
  late final int _rows = kMazeVariants.first.length;
  late final int _cols = kMazeVariants.first[0].length;
  late final _Point _start = _findChar(kMazeVariants.first, 'S');
  late final _Point _goal = _findChar(kMazeVariants.first, 'G');
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
  Timer? _cameraTimer;
  bool _cameraTour = false;
  bool _lookAtStart = false;
  bool _lookAtGoal = false;
  Offset _stickDirection = Offset.zero;
  bool _failed = false;
  String? _message;
  bool _finished = false;
  bool _won = false;
  bool _claimed = false;
  Offset? _board;
  Offset? _bombPickup;
  Offset? _plantedBomb;
  Offset? _cameraFocus;
  bool _carryingBomb = false;
  int _bombSeconds = 0;
  Timer? _fuse;
  Offset get _playerCell =>
      Offset(_playerCol.toDouble(), _playerRow.toDouble());
  double _distance(Offset a, Offset b) =>
      (a.dx - b.dx).abs() + (a.dy - b.dy).abs();
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
    final others = kMazeVariants.where((m) => m != _mazeRows).toList();
    return others[_rnd.nextInt(others.length)];
  }

  bool _isWall(int row, int col) {
    if (row < 0 || row >= _rows || col < 0 || col >= _cols) return true;
    return _mazeRows[row][col] == '#';
  }

  Timer _delay(Duration duration, void Function() callback) =>
      GameTimer(duration, callback, isPaused: () => _paused);
  Timer _repeat(Duration duration, void Function(Timer) callback) =>
      GameTimer.periodic(duration, callback, isPaused: () => _paused);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _holdTimer?.cancel();
      _field.pauseEngine();
    } else {
      _field.resumeEngine();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _introDone = !widget.showIntro;
    _resetLevelState();
    _field = MazeGame(
      rows: _mazeRows,
      player: Offset(_playerCol.toDouble(), _playerRow.toDouble()),
      goal: Offset(_currentGoal.col.toDouble(), _currentGoal.row.toDouble()),
      onReady: _onFieldReady,
    );
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    if (_fieldReady) _startOpeningTour();
  }

  void _onFieldReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fieldReady = true;
      if (_introDone) _startOpeningTour();
    });
  }

  void _resetLevelState() {
    _fuse?.cancel();
    _board = _bombPickup = _plantedBomb = _cameraFocus = null;
    _carryingBomb = false;
    _bombSeconds = 0;
    _holdTimer?.cancel();
    _cameraTimer?.cancel();
    _messageTimer?.cancel();
    _cameraTour = false;
    _lookAtStart = false;
    _lookAtGoal = false;
    _stickDirection = Offset.zero;
    _failed = false;
    _mazeRows = kMazeVariants.first;
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

  void _startOpeningTour() {
    _clock?.cancel();
    _cameraTimer?.cancel();
    setState(() {
      _cameraTour = true;
      _lookAtGoal = false;
    });
    _cameraTimer = _delay(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _lookAtGoal = true);
      // 1.6 seconds of camera travel, then one second at the target.
      _cameraTimer = _delay(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        setState(() => _lookAtGoal = false);
        _cameraTimer = _delay(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          setState(() => _cameraTour = false);
          _startClock();
        });
      });
    });
  }

  void _startClock() {
    _clock?.cancel();
    _clock = _repeat(const Duration(seconds: 1), (_) {
      if (_finished || _cameraTour) return;
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
    if (!_fieldReady || _paused || _finished || _cameraTour || _field.moving) {
      return;
    }
    final newRow = _playerRow + dRow;
    final newCol = _playerCol + dCol;
    final facing = _facingFor(dRow, dCol);
    if (_isWall(newRow, newCol)) {
      setState(() => _facing = facing);
      return;
    }
    if (_board == Offset(newCol.toDouble(), newRow.toDouble())) {
      setState(() => _message = '木板挡住了！拿炸弹，靠近木板放下。');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _playerRow = newRow;
      _playerCol = newCol;
      _facing = facing;
    });
    _syncField();
    if (_playerRow == _currentGoal.row && _playerCol == _currentGoal.col) {
      if (_board == null) _levelClear();
      return;
    }
    if (!_goalFled && _isAdjacentToCurrentGoal()) {
      _fleeGoal();
    }
  }

  void _fleeGoal() {
    _holdTimer?.cancel();
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
      _message = '它跑回起点啦！跟着镜头看看～';
      _cameraTour = true;
    });
    _syncField();
    // Allow the player relocation to settle before the guided camera tour.
    _cameraTimer = _delay(const Duration(milliseconds: 200), () {
      if (!mounted || _finished) return;
      setState(() => _lookAtStart = true);
      _cameraTimer = _delay(const Duration(milliseconds: 2600), () {
        if (!mounted || _finished) return;
        setState(() {
          _lookAtStart = false;
          _message = '他跑回去了！！出发追回它吧！';
        });
        _cameraTimer = _delay(const Duration(milliseconds: 1300), () {
          if (!mounted || _finished) return;
          final puzzle = mazeBombPuzzle(
            _mazeRows,
            _playerCell,
            Offset(_currentGoal.col.toDouble(), _currentGoal.row.toDouble()),
          );
          setState(() {
            _board = puzzle.board;
            _bombPickup = puzzle.bomb;
            _message = '木板掉下来了！附近有炸弹…';
          });
          _field.dropBoard(puzzle.board);
          HapticFeedback.heavyImpact();
          _cameraTimer = _delay(const Duration(milliseconds: 850), () {
            if (!mounted || _finished) return;
            setState(() {
              _cameraFocus = _bombPickup;
              _message = '去拿炸弹，靠近木板放下，3 秒后爆炸！';
            });
            _cameraTimer = _delay(const Duration(milliseconds: 2600), () {
              if (!mounted || _finished) return;
              setState(() => _cameraFocus = null);
              _cameraTimer = _delay(const Duration(milliseconds: 1700), () {
                if (!mounted || _finished) return;
                setState(() => _cameraTour = false);
              });
            });
          });
        });
      });
    });
  }

  void _fail() {
    _fuse?.cancel();
    _holdTimer?.cancel();
    _clock?.cancel();
    _cameraTimer?.cancel();
    _messageTimer?.cancel();
    setState(() {
      _finished = true;
      _failed = true;
      _message = null;
    });
  }

  void _levelClear() {
    _holdTimer?.cancel();
    _finished = true;
    _won = true;
    _clock?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _message = null);
  }

  @override
  void dispose() {
    _fuse?.cancel();
    _holdTimer?.cancel();
    _clock?.cancel();
    _messageTimer?.cancel();
    _cameraTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _takeBomb() {
    if (_cameraTour ||
        _finished ||
        _paused ||
        _bombPickup == null ||
        _distance(_playerCell, _bombPickup!) > 1) {
      return;
    }
    setState(() {
      _bombPickup = null;
      _carryingBomb = true;
      _message = '拿到了！靠近木板后放下炸弹。';
    });
  }

  void _plantBomb() {
    if (_cameraTour ||
        _finished ||
        _paused ||
        !_carryingBomb ||
        _board == null ||
        _distance(_playerCell, _board!) != 1) {
      return;
    }
    setState(() {
      _carryingBomb = false;
      _plantedBomb = _playerCell;
      _bombSeconds = 3;
      _message = '炸弹已放下，快退开！';
    });
    _fuse = _repeat(const Duration(seconds: 1), (timer) {
      if (!mounted || _finished) {
        timer.cancel();
        return;
      }
      setState(() => _bombSeconds--);
      if (_bombSeconds > 0) return;
      timer.cancel();
      _field.explode(_plantedBomb!);
      HapticFeedback.heavyImpact();
      setState(() {
        _board = null;
        _plantedBomb = null;
        _message = '木板炸开了！继续找布布！';
      });
      _messageTimer?.cancel();
      _messageTimer = _delay(const Duration(seconds: 2), () {
        if (mounted && !_finished) setState(() => _message = null);
      });
    });
  }

  void _onJoystick(Offset direction) {
    _holdTimer?.cancel();
    _stickDirection = direction;
    if (direction == Offset.zero || _cameraTour || _finished || _paused) return;
    void move() =>
        _move(_stickDirection.dy.toInt(), _stickDirection.dx.toInt());
    move();
    _holdTimer = _repeat(const Duration(milliseconds: 170), (_) => move());
  }

  void _syncField() {
    _field.setScene(
      rows: _mazeRows,
      player: Offset(_playerCol.toDouble(), _playerRow.toDouble()),
      goal: Offset(_currentGoal.col.toDouble(), _currentGoal.row.toDouble()),
    );
    _field.cameraTour = _cameraTour;
    _field.lookAtStart = _lookAtStart;
    _field.lookAtGoal = _lookAtGoal;
    _field.cameraFocus = _cameraFocus;
    _field.boardPosition = _board;
    _field.bombPickup = _bombPickup;
    _field.plantedBomb = _plantedBomb;
    _field.bombSeconds = _bombSeconds;
    _field.facingCol = _facing == _Facing.right
        ? 1
        : _facing == _Facing.left
        ? -1
        : 0;
    _field.facingRow = _facing == _Facing.down
        ? 1
        : _facing == _Facing.up
        ? -1
        : 0;
  }

  @override
  Widget build(BuildContext context) {
    _syncField();
    _field.reducedMotion = MediaQuery.disableAnimationsOf(context);
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
              const SizedBox(height: 6),
              const Text(
                '推动摇杆移动 · 松手停下',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GameWidget(
                      game: _field,
                      loadingBuilder: (_) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFBBD0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: MazeJoystick(
                  enabled: _introDone && !_cameraTour && !_finished && !_paused,
                  onChanged: _onJoystick,
                ),
              ),
              if (_board != null && !_cameraTour && !_finished)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: _paused
                        ? null
                        : _carryingBomb
                        ? (_distance(_playerCell, _board!) == 1
                              ? _plantBomb
                              : null)
                        : (_bombPickup != null &&
                                  _distance(_playerCell, _bombPickup!) <= 1
                              ? _takeBomb
                              : null),
                    child: Text(
                      _plantedBomb != null
                          ? '$_bombSeconds 秒后爆炸'
                          : _carryingBomb
                          ? '放下炸弹'
                          : '拿起炸弹',
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_won)
          GameKeyRewardOverlay(
            message: '成功找到布布 · 获得一把钥匙 ♡',
            onClaim: () {
              if (_claimed) return;
              _claimed = true;
              widget.onComplete();
            },
          ),
        if (_failed)
          GameFailureOverlay(
            title: '时间到啦！',
            onRetry: () {
              setState(_resetLevelState);
              _startOpeningTour();
            },
            onExit: widget.onLose,
          ),
        if (!_introDone)
          GameIntroOverlay(
            title: '迷宫大冒险',
            instructionText: '推动下方摇杆带布布走出迷宫～\n时间限制 $_timeLimit 秒，加油哦～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
