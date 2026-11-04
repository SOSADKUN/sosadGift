import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final VoidCallback? onComplete;
  final bool loop;
  final bool showTapToSkip;
  final bool landscape;
  final bool paused;
  final bool mixWithOthers;

  /// Show the entire frame within the phone's safe area from this timestamp.
  final Duration? containFrom;
  final Color containedBackgroundColor;
  final bool containInLandscape;

  const VideoPlayerWidget({
    super.key,
    required this.assetPath,
    this.onComplete,
    this.loop = false,
    this.showTapToSkip = true,
    this.landscape = false,
    this.paused = false,
    this.mixWithOthers = false,
    this.containFrom,
    this.containedBackgroundColor = Colors.black,
    this.containInLandscape = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _fired = false;
  bool _contain = false;

  @override
  void initState() {
    super.initState();

    if (widget.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    _controller =
        VideoPlayerController.asset(
            widget.assetPath,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: widget.mixWithOthers,
            ),
          )
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
            _controller.setLooping(widget.loop);
            if (!widget.paused) _controller.play();
          });

    _controller.addListener(_checkFinished);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused && _ready) {
      if (widget.paused) {
        _controller.pause();
      } else {
        _controller.play();
      }
    }
  }

  void _checkFinished() {
    if (!mounted) return;
    final threshold = widget.containFrom;
    final shouldContain =
        threshold != null && _controller.value.position >= threshold;
    if (_contain != shouldContain) {
      setState(() => _contain = shouldContain);
    }
    if (_fired || widget.loop) return;
    final value = _controller.value;
    if (value.isInitialized &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _fired = true;
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkFinished);
    _controller.dispose();

    if (widget.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.showTapToSkip
          ? () {
              if (!_fired) {
                _fired = true;
                widget.onComplete?.call();
              }
            }
          : null,
      child: _ready
          ? VideoFrameLayout(
              videoSize: _controller.value.size,
              contain: _contain,
              containInLandscape: widget.containInLandscape,
              backgroundColor: widget.containedBackgroundColor,
              child: VideoPlayer(_controller),
            )
          : const ColoredBox(color: Colors.black),
    );
  }
}

/// Keeps landscape diary footage edge-to-edge while retaining portrait framing.
class VideoFrameLayout extends StatelessWidget {
  const VideoFrameLayout({
    super.key,
    required this.videoSize,
    required this.child,
    required this.contain,
    this.containInLandscape = true,
    this.backgroundColor = Colors.black,
  });
  final Size videoSize;
  final Widget child;
  final bool contain;
  final bool containInLandscape;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fitEntireFrame =
          contain &&
          (containInLandscape || constraints.maxHeight >= constraints.maxWidth);
      return ColoredBox(
        color: fitEntireFrame ? backgroundColor : Colors.black,
        child: ClipRect(
          child: Padding(
            padding: fitEntireFrame
                ? MediaQuery.paddingOf(context)
                : EdgeInsets.zero,
            child: SizedBox.expand(
              child: FittedBox(
                fit: fitEntireFrame ? BoxFit.contain : BoxFit.cover,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
