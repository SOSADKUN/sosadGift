import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../models/story_entry.dart';
import 'story_video.dart';

/// A reversible, finger-controlled journey through photographs and captions.
class MemoryJourney extends StatefulWidget {
  const MemoryJourney({
    super.key,
    required this.entries,
    required this.onComplete,
  });

  final List<StoryEntry> entries;
  final VoidCallback onComplete;

  @override
  State<MemoryJourney> createState() => _MemoryJourneyState();
}

class _MemoryJourneyState extends State<MemoryJourney>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration? _lastTick;
  double _position = 0;
  int _direction = 0;
  int? _pointer;
  bool _completed = false;
  late List<({String year, String title, StoryStep? step})> _memories;

  static const _ink = Color(0xFF654E4C);
  static const _muted = Color(0xFFA0847C);

  @override
  void initState() {
    super.initState();
    _readEntries();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
  }

  void _readEntries() {
    _memories = [
      for (final entry in widget.entries) ...[
        (year: entry.year, title: entry.title, step: null),
        for (final step in entry.steps)
          (year: entry.year, title: entry.title, step: step),
      ],
    ];
  }

  @override
  void didUpdateWidget(MemoryJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _stop();
      _readEntries();
      _position = _position.clamp(0.0, _end);
    }
  }

  double get _end => math.max(0, _memories.length - 1).toDouble();
  int get _current =>
      _position.round().clamp(0, math.max(0, _memories.length - 1));

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null) return;
    final dt = math.min(.05, (elapsed - previous).inMicroseconds / 1000000);
    final next = (_position + _direction * dt * .40).clamp(0.0, _end);
    if (next == _position) {
      _stop();
    } else {
      setState(() => _position = next);
    }
  }

  void _hold(PointerDownEvent event, double width) {
    if (_pointer != null || _memories.isEmpty) return;
    _pointer = event.pointer;
    setState(() => _direction = event.localPosition.dx < width / 2 ? -1 : 1);
    _lastTick = null;
    _ticker.start();
  }

  void _stop() {
    _ticker.stop();
    _lastTick = null;
    _pointer = null;
    if (_direction != 0 && mounted) setState(() => _direction = 0);
  }

  void _release(PointerEvent event) {
    if (event.pointer == _pointer) _stop();
  }

  void _step(int direction) {
    _stop();
    if (_memories.isEmpty) return;
    setState(
      () => _position = (_current + direction).clamp(0.0, _end).toDouble(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: const Color(0xFFFAF5EF),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.15),
            radius: 1.1,
            colors: [Color(0xFFFFFCF7), Color(0xFFF0E1DC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUR LITTLE STORY',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2.4,
                              color: _muted,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '往年生日回忆',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _memories.isEmpty
                          ? '00 / 00'
                          : '${(_current + 1).toString().padLeft(2, '0')} / ${_memories.length.toString().padLeft(2, '0')}',
                      key: const ValueKey('memory-counter'),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final photoWidth = math.min(330.0, box.maxWidth * .76);
                    final photoHeight = math.min(360.0, box.maxHeight * .55);
                    return FocusableActionDetector(
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.arrowLeft):
                            _MoveIntent(-1),
                        SingleActivator(LogicalKeyboardKey.arrowRight):
                            _MoveIntent(1),
                      },
                      actions: {
                        _MoveIntent: CallbackAction<_MoveIntent>(
                          onInvoke: (intent) {
                            _step(intent.direction);
                            return null;
                          },
                        ),
                      },
                      autofocus: true,
                      child: Listener(
                        key: const ValueKey('memory-hold-area'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) => _hold(event, box.maxWidth),
                        onPointerUp: _release,
                        onPointerCancel: _release,
                        child: ClipRect(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: _direction < 0
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        end: _direction < 0
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFE6C5BE).withValues(
                                            alpha: _direction == 0 ? 0 : .24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_memories.isEmpty)
                                const Center(
                                  child: Text(
                                    '故事即将开始 ♡',
                                    style: TextStyle(color: _ink),
                                  ),
                                ),
                              for (
                                var i = math.min(
                                  _memories.length - 1,
                                  _current + 3,
                                );
                                i >= math.max(0, _current - 1);
                                i--
                              )
                                if (i - _position > -1 && i - _position < 3.5)
                                  if (_memories[_current].step != null &&
                                      _memories[i].step != null &&
                                      _memories[i].year ==
                                          _memories[_current].year)
                                    _photo(i, photoWidth, photoHeight, reduced),
                              if (_memories.isNotEmpty)
                                if (_memories[_current].step == null)
                                  _chapter(reduced)
                                else
                                  _caption(box.maxHeight, photoHeight, reduced),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _navigation(Icons.west_rounded, '上一段回忆', -1),
                        Expanded(
                          child: Text(
                            _direction < 0
                                ? '正在倒回时光…'
                                : _direction > 0
                                ? '回忆中…'
                                : '按住左侧倒回 · 按住右侧前行',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                        ),
                        _navigation(Icons.east_rounded, '下一段回忆', 1),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _memories.isEmpty
                            ? 0
                            : (_position / math.max(1, _end)).clamp(0, 1),
                        minHeight: 2,
                        color: const Color(0xFFB88C85),
                        backgroundColor: const Color(0xFFE6D8D1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '松开停留，让回忆慢一点。',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_completed) return;
                            _completed = true;
                            _stop();
                            widget.onComplete();
                          },
                          style: TextButton.styleFrom(foregroundColor: _ink),
                          child: const Text(
                            '下一页  ↗',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chapter(bool reduced) {
    final chapter = _memories[_current];
    final distance = (_current - _position).abs();
    return Center(
      child: Opacity(
        opacity: reduced ? 1 : (1 - distance / .65).clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              key: ValueKey('story-chapter-${chapter.year}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${chapter.year}年',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 18,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(width: 36, height: 1, color: const Color(0xFFD5B9B6)),
                const SizedBox(height: 20),
                Text(
                  chapter.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigation(IconData icon, String label, int direction) => IconButton(
    tooltip: label,
    onPressed: () => _step(direction),
    icon: Icon(icon, size: 18, color: _ink),
  );

  Widget _photo(int index, double width, double height, bool reduced) {
    final distance = index - _position;
    final scale = reduced ? 1.0 : 1 / (1 + math.max(-.65, distance) * .85);
    final opacity = reduced
        ? (index == _current ? 1.0 : 0.0)
        : (distance < 0 ? 1 + distance : 1 - distance * .26).clamp(0.0, 1.0);
    final image = _memories[index].step!.imageAsset;
    final video = _memories[index].step!.videoAsset;
    return Center(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: reduced
                ? Offset.zero
                : Offset(
                    (index.isEven ? -1 : 1) * math.max(0, distance) * 32,
                    -math.max(0, distance) * 20,
                  ),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: reduced ? 0 : (index.isEven ? -.025 : .025),
                child: RepaintBoundary(
                  child: Container(
                    key: ValueKey('memory-photo-$index'),
                    constraints: BoxConstraints(
                      maxWidth: width,
                      maxHeight: height,
                    ),
                    padding: const EdgeInsets.fromLTRB(9, 9, 9, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDFA),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x226A4842),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: video != null
                        ? StoryVideo(
                            key: ValueKey(video),
                            asset: video,
                            active: index == _current && _direction == 0,
                          )
                        : image == null
                        ? SizedBox(
                            width: width - 18,
                            height: height - 33,
                            child: _placeholder(index),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (_, error, stack) => SizedBox(
                              width: width - 18,
                              height: height - 33,
                              child: _placeholder(index),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(int index) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: index.isEven
            ? const [Color(0xFFEAD8CC), Color(0xFFD5B9B6)]
            : const [Color(0xFFDCE0CF), Color(0xFFB9C4B2)],
      ),
    ),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined, color: Colors.white70, size: 30),
          SizedBox(height: 10),
          Text(
            '等待放入我们的照片',
            style: TextStyle(fontSize: 11, color: Color(0xFF705D57)),
          ),
        ],
      ),
    ),
  );

  Widget _caption(double height, double photoHeight, bool reduced) {
    final memory = _memories[_current];
    final distance = (_current - _position).abs();
    final opacity = reduced ? 1.0 : (1 - distance / .65).clamp(0.0, 1.0);
    final above = _current.isEven;
    final space = math.max(0.0, (height - photoHeight) / 2 - 14);
    return Positioned(
      left: 28,
      right: 28,
      top: above ? 0 : null,
      bottom: above ? null : 0,
      height: space,
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  memory.year.toUpperCase(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memory.step!.sentence,
                  key: const ValueKey('memory-caption'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.direction);
  final int direction;
}
