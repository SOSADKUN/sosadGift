import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'animated_game_assets.dart';

/// Flame owns the maze's drawing, sprite animation, movement and camera easing.
class MazeGame extends FlameGame {
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
  SpriteAnimationTicker? _walker;
  SpriteAnimationTicker? _heart;
  List<String> _rows = [];
  Offset _player = Offset.zero;
  Offset _from = Offset.zero;
  Offset _destination = Offset.zero;
  Offset _goal = Offset.zero;
  Offset _camera = Offset.zero;
  double _tourTime = 0;
  Offset _tourFrom = Offset.zero;
  Offset _tourTo = Offset.zero;
  bool? _tourFocus;
  bool _hasSized = false;
  double _moveTime = 1;
  double _phase = 0;
  double _cell = 48;
  int facingRow = 0;
  int facingCol = -1;
  bool cameraTour = false;
  bool lookAtStart = false;
  bool lookAtGoal = false;
  bool reducedMotion = false;
  ui.Picture? _walls;
  final List<Offset> _trail = [];
  final Set<Offset> _visited = {};

  Offset get cameraOffset => _camera;
  Offset get playerPosition => _player;
  double get worldWidth => _rows.isEmpty ? 0 : _rows.first.length * _cell;
  double get worldHeight => _rows.length * _cell;
  double get cellSize => _cell;
  bool get moving => _moveTime < .14;

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
    final focus = lookAtGoal
        ? _goal
        : lookAtStart
        ? const Offset(1, 1)
        : _player;
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
    _walker?.update(step);
    _heart?.update(step);
    _moveTime += step;
    final progress = reducedMotion
        ? 1.0
        : Curves.easeOutCubic.transform((_moveTime / .14).clamp(0.0, 1.0));
    _player = Offset.lerp(_from, _destination, progress)!;
    final target = _cameraTarget;
    if (cameraTour) {
      if (_tourFocus != (lookAtStart || lookAtGoal)) {
        _tourFocus = lookAtStart || lookAtGoal;
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
    final goalCenter = (_goal + const Offset(.5, .5)) * _cell;
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
      position: Vector2(goalCenter.dx - _cell * .4, goalCenter.dy - _cell * .4),
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
    if (facingCol == 1) canvas.scale(-1, 1);
    if (facingRow != 0) canvas.rotate(facingRow < 0 ? pi / 2 : -pi / 2);
    final bob = reducedMotion || !moving
        ? 0.0
        : sin(_moveTime / .14 * pi) * _cell * .035;
    _walker?.getSprite().render(
      canvas,
      position: Vector2(-_cell * .4, -_cell * .4 - bob),
      size: Vector2.all(_cell * .8),
    );
    canvas.restore();
    canvas.restore();
    _minimap(canvas);
  }

  ui.Picture _createWalls() {
    _buildWalls();
    return _walls!;
  }

  void _minimap(Canvas canvas) {
    final unit = min(110.0 / _rows.first.length, 100.0 / _rows.length);
    final width = _rows.first.length * unit;
    final height = _rows.length * unit;
    final left = size.x - width - 20;
    const top = 16.0;
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
    canvas.drawCircle(
      Offset(left + (_goal.dx + .5) * unit, top + (_goal.dy + .5) * unit),
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
    _library.dispose();
    super.onRemove();
  }
}
