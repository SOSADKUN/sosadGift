import 'package:flutter/material.dart';

class MazeJoystick extends StatefulWidget {
  const MazeJoystick({
    super.key,
    required this.enabled,
    required this.onChanged,
  });
  final bool enabled;
  final ValueChanged<Offset> onChanged;
  @override
  State<MazeJoystick> createState() => _MazeJoystickState();
}

class _MazeJoystickState extends State<MazeJoystick> {
  Offset _knob = Offset.zero;
  Offset _direction = Offset.zero;
  int? _pointer;

  void _update(Offset position) {
    final delta = position - const Offset(60, 60);
    final knob = delta.distance > 38 ? delta / delta.distance * 38 : delta;
    final direction = delta.distance < 12
        ? Offset.zero
        : delta.dx.abs() > delta.dy.abs()
        ? Offset(delta.dx.sign, 0)
        : Offset(0, delta.dy.sign);
    setState(() => _knob = knob);
    if (direction != _direction) {
      _direction = direction;
      widget.onChanged(direction);
    }
  }

  void _reset() {
    _pointer = null;
    setState(() {
      _knob = Offset.zero;
      _direction = Offset.zero;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  void didUpdateWidget(MazeJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _knob = Offset.zero;
      _direction = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '迷宫摇杆，推动选择方向，松手停止',
    child: Listener(
      key: const ValueKey('maze-joystick'),
      onPointerDown: (event) {
        if (!widget.enabled || _pointer != null) return;
        _pointer = event.pointer;
        _update(event.localPosition);
      },
      onPointerMove: (event) {
        if (widget.enabled && _pointer == event.pointer) {
          _update(event.localPosition);
        }
      },
      onPointerUp: (event) {
        if (_pointer == event.pointer) _reset();
      },
      onPointerCancel: (event) {
        if (_pointer == event.pointer) _reset();
      },
      child: Opacity(
        opacity: widget.enabled ? 1 : .35,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x443C294A),
            border: Border.all(color: const Color(0x66F7D8E8), width: 2),
          ),
          child: Center(
            child: Transform.translate(
              offset: _knob,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFE7F1), Color(0xFFD59DBF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x66EABBD2), blurRadius: 16),
                  ],
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  color: Color(0xFF69415B),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
