import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Only the selected memory plays; neighboring cards and background apps pause.
class StoryVideo extends StatefulWidget {
  const StoryVideo({
    super.key,
    required this.asset,
    required this.active,
    this.volume = 0,
    this.showControls = false,
  });
  final String asset;
  final bool active;
  final double volume;
  final bool showControls;

  @override
  State<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _foreground = true;
  bool _manuallyPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(widget.asset);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setLooping(true);
      await _controller.setVolume(widget.volume);
      if (!mounted) return;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _syncPlayback() {
    if (!_ready) return;
    final operation = widget.active && _foreground && !_manuallyPaused
        ? _controller.play()
        : _controller.pause();
    operation.catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void didUpdateWidget(StoryVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) _manuallyPaused = false;
      _syncPlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(
          Icons.videocam_off_outlined,
          color: Color(0xFFA0847C),
          size: 32,
        ),
      );
    }
    if (!_ready) {
      return const Center(
        child: Icon(Icons.movie_outlined, color: Color(0xFFA0847C), size: 32),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(
          BoxFit.contain,
          _controller.value.size,
          Size(constraints.maxWidth, constraints.maxHeight),
        ).destination;
        return SizedBox(
          width: fitted.width,
          height: fitted.height,
          child: widget.showControls
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(_controller),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        tooltip: _manuallyPaused ? '播放' : '暂停',
                        onPressed: () {
                          setState(() => _manuallyPaused = !_manuallyPaused);
                          _syncPlayback();
                        },
                        icon: Icon(
                          _manuallyPaused ? Icons.play_arrow : Icons.pause,
                        ),
                      ),
                    ),
                  ],
                )
              : VideoPlayer(_controller),
        );
      },
    );
  }
}
