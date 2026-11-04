import 'package:flutter/material.dart';

/// Four discrete directions: one step on press, continuous travel while held.
class MazeDirectionPad extends StatefulWidget {
  const MazeDirectionPad({
    super.key,
    required this.enabled,
    required this.onChanged,
  });
  final bool enabled;
  final ValueChanged<Offset> onChanged;
  @override
  State<MazeDirectionPad> createState() => _MazeDirectionPadState();
}

class _MazeDirectionPadState extends State<MazeDirectionPad> {
  int? _pointer;
  Offset _direction = Offset.zero;

  void _stop() {
    if (_pointer == null) return;
    _pointer = null;
    setState(() => _direction = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  void didUpdateWidget(MazeDirectionPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _direction = Offset.zero;
    }
  }

  Widget _button(String name, IconData icon, Offset direction) => Semantics(
    label:
        '向${{'up': '上', 'down': '下', 'left': '左', 'right': '右'}[name]}移动，长按连续移动',
    button: true,
    enabled: widget.enabled,
    onTap: widget.enabled
        ? () {
            widget.onChanged(direction);
            widget.onChanged(Offset.zero);
          }
        : null,
    child: Listener(
      key: ValueKey('maze-$name'),
      onPointerDown: (event) {
        if (!widget.enabled || _pointer != null) return;
        _pointer = event.pointer;
        setState(() => _direction = direction);
        widget.onChanged(direction);
      },
      onPointerUp: (event) {
        if (_pointer == event.pointer) _stop();
      },
      onPointerCancel: (event) {
        if (_pointer == event.pointer) _stop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _direction == direction
              ? const Color(0xFFF7C1D8)
              : const Color(0xEE523749),
          border: Border.all(color: const Color(0xFFDBAEC3), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: _direction == direction
              ? const Color(0xFF58384D)
              : Colors.white,
          size: 29,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: widget.enabled ? 1 : .4,
    child: SizedBox(
      width: 172,
      height: 152,
      child: Column(
        children: [
          _button('up', Icons.keyboard_arrow_up_rounded, const Offset(0, -1)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _button(
                'left',
                Icons.keyboard_arrow_left_rounded,
                const Offset(-1, 0),
              ),
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFDFA4BE),
                size: 18,
              ),
              _button(
                'right',
                Icons.keyboard_arrow_right_rounded,
                const Offset(1, 0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _button(
            'down',
            Icons.keyboard_arrow_down_rounded,
            const Offset(0, 1),
          ),
        ],
      ),
    ),
  );
}
