import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animated_game_assets.dart';

enum MazeCharacterView { front, back, left, right }

/// Flame owns the maze's drawing, sprite animation, movement and camera easing.
class MazeGame extends FlameGame {
  // Leave one input tick for the final rendered frame to settle.
  static const moveRepeatInterval = Duration(milliseconds: 176);
  static const _moveSeconds = .16;
  MazeGame({
    required List<String> rows,
    required Offset player,
    required Offset goal,
    this.onReady,
  }) {
    setScene(rows: rows, player: player, goal: goal);
  }
  final VoidCallback? onReady;
  final _library = AnimatedGameAssets();
  final minimapRevision = ValueNotifier(0);
  double _mapElapsed = 0;
  SpriteAnimationTicker? _walker;
  SpriteAnimationTicker? _heart;
  ui.Image? _verticalImage;
  Sprite? _front;
  Sprite? _back;
  Offset? boardPosition;
  Offset? bombPickup;
  bool carryingBomb = false;
  Offset? _collectFrom;
  double _collectTime = 1;
  List<Offset> _escapeRoute = [];
  double _escapeTime = 3;
  static const _escapeSeconds = 2.6;

  bool get targetEscaping => _escapeTime < _escapeSeconds;
  Offset get targetPosition {
    if (!targetEscaping || _escapeRoute.isEmpty) return _goal;
    final distance = (_escapeTime / _escapeSeconds) * (_escapeRoute.length - 1);
    final index = distance.floor().clamp(0, _escapeRoute.length - 2);
    return Offset.lerp(
      _escapeRoute[index],
      _escapeRoute[index + 1],
      distance - index,
    )!;
  }

  /// Run through open corridors while the Flame camera follows the target.
  void fleeTarget(Offset from) {
    final queue = <Offset>[from];
    final parents = <Offset, Offset?>{from: null};
    for (var i = 0; i < queue.length; i++) {
      if (queue[i] == _goal) break;
      for (final direction in const [
        Offset(-1, 0),
        Offset(0, -1),
        Offset(1, 0),
        Offset(0, 1),
      ]) {
        final next = queue[i] + direction;
        final x = next.dx.toInt(), y = next.dy.toInt();
        if (y < 0 ||
            y >= _rows.length ||
            x < 0 ||
            x >= _rows[y].length ||
            _rows[y][x] == '#' ||
            parents.containsKey(next)) {
          continue;
        }
        parents[next] = queue[i];
        queue.add(next);
      }
    }
    if (!parents.containsKey(_goal)) return;
    final route = <Offset>[];
    for (Offset? p = _goal; p != null; p = parents[p]) {
      route.add(p);
    }
    _escapeRoute = route.reversed.toList();
    if (_escapeRoute.length < 2) return;
    _escapeTime = reducedMotion ? _escapeSeconds : 0;
  }

  void collectBomb(Offset from) {
    _collectFrom = from;
    _collectTime = reducedMotion ? .5 : 0;
  }

  Offset? plantedBomb;
  Offset? cameraFocus;
  int bombSeconds = 0;
  double _fallTime = 1;
  double _explosionTime = 10;
  Offset? _blastPosition;

  void dropBoard(Offset position) {
    boardPosition = position;
    _fallTime = 0;
  }

  void explode(Offset position) {
    _blastPosition = position;
    _explosionTime = 0;
  }

  List<String> _rows = [];
  Offset _player = Offset.zero;
  Offset _from = Offset.zero;
  Offset _destination = Offset.zero;
  Offset _goal = Offset.zero;
  Offset _camera = Offset.zero;
  double _tourTime = 0;
  Offset _tourFrom = Offset.zero;
  Offset _tourTo = Offset.zero;
  Offset? _tourFocus;
  bool _hasSized = false;
  double _moveTime = 1;
  double _phase = 0;
  double _cell = 48;
  int facingRow = 0;
  int facingCol = 1;
  bool _facesRight = true;
  bool cameraTour = false;
  bool lookAtStart = false;
  bool lookAtGoal = false;
  bool reducedMotion = false;
  ui.Picture? _walls;
  final List<Offset> _trail = [];
  final Set<Offset> _visited = {};

  List<String> get mazeRows => List.unmodifiable(_rows);
  Offset get cameraOffset => _camera;
  Offset get playerPosition => _player;
  double get worldWidth => _rows.isEmpty ? 0 : _rows.first.length * _cell;
  double get worldHeight => _rows.length * _cell;
  double get cellSize => _cell;
  bool get moving => _moveTime < _moveSeconds;

  /// Vertical travel retains the last horizontal facing; the bear stays upright.
  bool get playerFacesRight => _facesRight;
  MazeCharacterView get characterView => facingRow < 0
      ? MazeCharacterView.back
      : facingRow > 0
      ? MazeCharacterView.front
      : _facesRight
      ? MazeCharacterView.right
      : MazeCharacterView.left;

  double get playerBob => reducedMotion || !moving
      ? 0
      : sin((_moveTime / _moveSeconds).clamp(0.0, 1.0) * pi) * _cell * .02;

  void setScene({
    required List<String> rows,
    required Offset player,
    required Offset goal,
  }) {
    final changedMaze = !identical(rows, _rows);
    if (changedMaze) {
      _rows = rows;
      _walls?.dispose();
      _walls = null;
      _trail.clear();
      _visited.clear();
    }
    if (player != _destination || changedMaze) {
      _from = _player;
      _destination = player;
      _moveTime = 0;
      if (changedMaze || (_from - player).distance > 1.1) {
        _player = player;
        _from = player;
        _moveTime = 1;
      } else {
        _trail.add(_from);
        if (_trail.length > 10) _trail.removeAt(0);
      }
      _visited.add(player);
    }
    _goal = goal;
  }

  @override
  Color backgroundColor() => Colors.white;

  @override
  Future<void> onLoad() async {
    await _library.load([
      'assets/photos/game3_move.gif',
      'assets/photos/game3_1.gif',
    ]);
    _walker = _library.animation('assets/photos/game3_move.gif').createTicker();
    _heart = _library.animation('assets/photos/game3_1.gif').createTicker();
    final data = await rootBundle.load('assets/photos/maze_vertical.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: 640,
    );
    try {
      final image = (await codec.getNextFrame()).image;
      _verticalImage = image;
      final scale = image.width / 1254;
      _front = Sprite(
        image,
        srcPosition: Vector2(70 * scale, 298 * scale),
        srcSize: Vector2(515 * scale, 690 * scale),
      );
      _back = Sprite(
        image,
        srcPosition: Vector2(659 * scale, 298 * scale),
        srcSize: Vector2(518 * scale, 690 * scale),
      );
    } finally {
      codec.dispose();
    }
    onReady?.call();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final oldCell = _cell;
    _cell = max(size.x / 7, size.y / 9);
    _walls?.dispose();
    _walls = null;
    if (!_hasSized) {
      _camera = _cameraTarget;
      _hasSized = true;
    } else {
      // A message changes viewport height. Preserve position instead of jumping
      // straight to the tour destination when Flutter lays out the new height.
      _camera = Offset(
        (_camera.dx / oldCell * _cell).clamp(
          0.0,
          max(0.0, worldWidth - size.x),
        ),
        (_camera.dy / oldCell * _cell).clamp(
          0.0,
          max(0.0, worldHeight - size.y),
        ),
      );
      if (_tourFocus != null) {
        _tourFrom = _camera;
        _tourTo = _cameraTarget;
        _tourTime = 0;
      }
    }
  }

  Offset get _cameraTarget {
    final focus =
        (targetEscaping ? targetPosition : null) ??
        cameraFocus ??
        (lookAtGoal
            ? _goal
            : lookAtStart
            ? const Offset(1, 1)
            : _player);
    return Offset(
      ((focus.dx + .5) * _cell - size.x / 2).clamp(
        0.0,
        max(0.0, worldWidth - size.x),
      ),
      ((focus.dy + .5) * _cell - size.y / 2).clamp(
        0.0,
        max(0.0, worldHeight - size.y),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final step = min(dt, .2);
    _phase += step;
    _mapElapsed += step;
    if (_mapElapsed >= .08) {
      _mapElapsed = 0;
      minimapRevision.value++;
    }
    if (facingCol != 0) _facesRight = facingCol > 0;
    if (moving && !reducedMotion) _walker?.update(step);
    _heart?.update(step);
    _fallTime += step;
    _explosionTime += step;
    _escapeTime += step;
    _collectTime += step;
    _moveTime += step;
    final progress = reducedMotion
        ? 1.0
        : (_moveTime / _moveSeconds).clamp(0.0, 1.0);
    _player = Offset.lerp(_from, _destination, progress)!;
    final target = _cameraTarget;
    if (cameraTour && !targetEscaping) {
      if (_tourFocus != target) {
        _tourFocus = target;
        _tourFrom = _camera;
        _tourTo = target;
        _tourTime = 0;
      }
      _tourTime += step;
      final travel = reducedMotion
          ? 1.0
          : Curves.easeInOutCubic.transform((_tourTime / 1.6).clamp(0.0, 1.0));
      _camera = Offset.lerp(_tourFrom, _tourTo, travel)!;
    } else {
      _tourFocus = null;
      _camera = reducedMotion
          ? target
          : Offset.lerp(_camera, target, 1 - exp(-step * 12))!;
    }
  }

  void _buildWalls() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, worldWidth, worldHeight),
      Paint()..color = Colors.white,
    );
    for (var row = 0; row < _rows.length; row++) {
      for (var col = 0; col < _rows[row].length; col++) {
        final rect = Rect.fromLTWH(col * _cell, row * _cell, _cell, _cell);
        if (_rows[row][col] == '#') {
          final block = RRect.fromRectAndRadius(
            rect.deflate(1.5),
            const Radius.circular(7),
          );
          canvas.drawRRect(
            block.shift(const Offset(0, 4)),
            Paint()..color = const Color(0xAA0F0C17),
          );
          canvas.drawRRect(
            block,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7F627B), Color(0xFF4C3B56)],
              ).createShader(rect),
          );
          canvas.drawLine(
            rect.topLeft + const Offset(8, 5),
            rect.topRight + const Offset(-8, 5),
            Paint()
              ..strokeWidth = 1
              ..color = const Color(0x559F869F),
          );
        } else {
          canvas.drawCircle(
            rect.center,
            1,
            Paint()..color = const Color(0x227F6C8C),
          );
        }
      }
    }
    _walls = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_rows.isEmpty || !hasLayout) return;
    _walls ??= _createWalls();
    canvas.save();
    canvas.clipRect(Offset.zero & size.toSize());
    canvas.translate(-_camera.dx, -_camera.dy);
    canvas.drawPicture(_walls!);
    _renderPuzzle(canvas);
    for (var i = 0; i < _trail.length; i++) {
      final position = (_trail[i] + const Offset(.5, .5)) * _cell;
      canvas.drawCircle(
        position,
        _cell * .055,
        Paint()
          ..color = const Color(
            0xFFAA7C6C,
          ).withValues(alpha: .12 + .24 * i / max(1, _trail.length)),
      );
    }
    final goalCenter = (targetPosition + const Offset(.5, .5)) * _cell;
    final runBob = targetEscaping && !reducedMotion
        ? sin(_escapeTime * 32).abs() * _cell * .09
        : 0.0;
    final pulse = reducedMotion ? 1.0 : 1 + sin(_phase * 3) * .1;
    canvas.drawCircle(
      goalCenter,
      _cell * .45 * pulse,
      Paint()
        ..color = const Color(0x55FF88BB)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    _heart?.getSprite().render(
      canvas,
      position: Vector2(
        goalCenter.dx - _cell * .4,
        goalCenter.dy - _cell * .4 - runBob,
      ),
      size: Vector2.all(_cell * .8),
    );
    final playerCenter = (_player + const Offset(.5, .5)) * _cell;
    canvas.drawOval(
      Rect.fromCenter(
        center: playerCenter + Offset(0, _cell * .3),
        width: _cell * .6,
        height: _cell * .16,
      ),
      Paint()..color = const Color(0x77000000),
    );
    canvas.save();
    canvas.translate(playerCenter.dx, playerCenter.dy);
    final vertical =
        characterView == MazeCharacterView.front ||
        characterView == MazeCharacterView.back;
    if (!vertical && playerFacesRight) canvas.scale(-1, 1);
    if (vertical && moving && !reducedMotion) {
      canvas.rotate(sin(_moveTime / _moveSeconds * pi * 2) * .025);
    }
    final sprite = switch (characterView) {
      MazeCharacterView.front => _front,
      MazeCharacterView.back => _back,
      _ => _walker?.getSprite(),
    };
    // The front/back artwork fills its frame more than the side animation.
    // Reduce it uniformly and keep the feet on the same baseline when turning.
    final spriteWidth = _cell * (vertical ? .48 : .8);
    final spriteHeight = _cell * (vertical ? .64 : .8);
    sprite?.render(
      canvas,
      position: Vector2(
        -spriteWidth / 2,
        _cell * .4 - spriteHeight - playerBob,
      ),
      size: Vector2(spriteWidth, spriteHeight),
    );
    canvas.restore();
    canvas.restore();
    // Explosion is drawn in world coordinates above the player and barricade.
    canvas.save();
    canvas.clipRect(Offset.zero & size.toSize());
    canvas.translate(-_camera.dx, -_camera.dy);
    if (_explosionTime < 1 && _blastPosition != null) {
      final c = (_blastPosition! + const Offset(.5, .5)) * _cell;
      final life = (1 - _explosionTime).clamp(0.0, 1.0);
      final radius = _cell * (.2 + _explosionTime * 1.3);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.yellow.withValues(alpha: life),
              Colors.deepOrange.withValues(alpha: life * .8),
              Colors.orange.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
      canvas.drawCircle(
        c,
        radius * .85,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * life
          ..color = const Color(0xFFFFAD42).withValues(alpha: life),
      );
      for (var i = 0; i < 14; i++) {
        final a = i * 2.399;
        final d = _explosionTime * _cell * (1 + i % 3);
        canvas.drawCircle(
          c +
              Offset(
                cos(a) * d,
                sin(a) * d + _explosionTime * _explosionTime * _cell,
              ),
          3 * (1 - _explosionTime),
          Paint()..color = const Color(0xFFAA7044),
        );
      }
    }
    canvas.restore();
  }

  void _renderPuzzle(Canvas canvas) {
    if (boardPosition case final position?) {
      final fall = Curves.bounceOut.transform((_fallTime / .7).clamp(0.0, 1.0));
      final c =
          (position + const Offset(.5, .5)) * _cell -
          Offset(0, (1 - fall) * _cell * 5);
      for (var i = 0; i < 3; i++) {
        final rect = Rect.fromCenter(
          center: c + Offset(0, (i - 1) * _cell * .24),
          width: _cell * .94,
          height: _cell * .23,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = const Color(0xFFAA7044),
        );
        canvas.drawLine(
          rect.centerLeft + const Offset(4, 0),
          rect.centerRight - const Offset(4, 0),
          Paint()
            ..color = const Color(0xFF70452C)
            ..strokeWidth = 2,
        );
        for (final x in [-.35, .35]) {
          canvas.drawCircle(
            rect.center + Offset(_cell * x, 0),
            2,
            Paint()..color = const Color(0xFFE6D4B0),
          );
        }
      }
    }
    final collecting = _collectFrom != null && _collectTime < .5;
    final progress = Curves.easeInOutCubic.transform(
      (_collectTime / .5).clamp(0.0, 1.0),
    );
    final hand = _player + const Offset(.32, -.12);
    final flyingBomb = collecting
        ? Offset.lerp(_collectFrom, hand, progress)! -
              Offset(0, sin(progress * pi) * .65)
        : null;
    for (final item in [
      (bombPickup, 1.0, false),
      (plantedBomb, 1.0, true),
      (flyingBomb, 1 - progress * .45, false),
      (carryingBomb && !collecting ? hand : null, .55, false),
    ]) {
      final position = item.$1;
      if (position == null) continue;
      final c = (position + const Offset(.5, .5)) * _cell;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(item.$2);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawCircle(
        c,
        _cell * .24,
        Paint()..color = const Color(0xFF302B42),
      );
      canvas.drawCircle(
        c - Offset(_cell * .07, _cell * .08),
        _cell * .07,
        Paint()..color = const Color(0xFF79708C),
      );
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - _cell * .23)
          ..quadraticBezierTo(
            c.dx,
            c.dy - _cell * .42,
            c.dx + _cell * .14,
            c.dy - _cell * .35,
          ),
        Paint()
          ..color = const Color(0xFFB99459)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      if (item.$3) {
        canvas.drawCircle(
          c + Offset(_cell * .14, -_cell * .35),
          _cell * .05,
          Paint()..color = Colors.orangeAccent,
        );
      }
      if (item.$3) {
        final text = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: '$bombSeconds',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: _cell * .35,
              fontWeight: FontWeight.bold,
            ),
          ),
        )..layout();
        text.paint(canvas, c - Offset(text.width / 2, _cell * .65));
      }
      canvas.restore();
    }
  }

  ui.Picture _createWalls() {
    _buildWalls();
    return _walls!;
  }

  void renderMinimap(Canvas canvas, Size viewport) {
    if (_rows.isEmpty) return;
    final unit = min(
      (viewport.width - 14) / _rows.first.length,
      (viewport.height - 14) / _rows.length,
    );
    final width = _rows.first.length * unit;
    final height = _rows.length * unit;
    final left = (viewport.width - width) / 2;
    final top = (viewport.height - height) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 7, top - 7, width + 14, height + 14),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xDD17121F),
    );
    for (var r = 0; r < _rows.length; r++) {
      for (var c = 0; c < _rows[r].length; c++) {
        if (_rows[r][c] == '#') {
          canvas.drawRect(
            Rect.fromLTWH(
              left + c * unit,
              top + r * unit,
              unit - .5,
              unit - .5,
            ),
            Paint()..color = const Color(0xFF79627E),
          );
        } else if (_visited.contains(Offset(c.toDouble(), r.toDouble()))) {
          canvas.drawCircle(
            Offset(left + (c + .5) * unit, top + (r + .5) * unit),
            unit * .2,
            Paint()..color = const Color(0xFFBEA083),
          );
        }
      }
    }
    for (final marker in [
      (bombPickup, const Color(0xFFFFBD59)),
      (boardPosition, const Color(0xFFCD8B5A)),
    ]) {
      final p = marker.$1;
      if (p != null) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(left + (p.dx + .5) * unit, top + (p.dy + .5) * unit),
            width: unit * .9,
            height: unit * .9,
          ),
          Paint()..color = marker.$2,
        );
      }
    }
    canvas.drawCircle(
      Offset(
        left + (targetPosition.dx + .5) * unit,
        top + (targetPosition.dy + .5) * unit,
      ),
      unit * .55,
      Paint()..color = const Color(0xFFFF8FB8),
    );
    canvas.drawCircle(
      Offset(left + (_player.dx + .5) * unit, top + (_player.dy + .5) * unit),
      unit * .55,
      Paint()..color = const Color(0xFFFFE0A6),
    );
  }

  @override
  void onRemove() {
    _walls?.dispose();
    _walls = null;
    minimapRevision.dispose();
    _verticalImage?.dispose();
    _library.dispose();
    super.onRemove();
  }
}
