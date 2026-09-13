import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  final VoidCallback? onComplete;
  final bool loop;
  final bool showTapToSkip;
  final bool landscape;

  /// Show the entire frame within the phone's safe area from this timestamp.
  final Duration? containFrom;
  final Color containedBackgroundColor;

  const VideoPlayerWidget({
    super.key,
    required this.assetPath,
    this.onComplete,
    this.loop = false,
    this.showTapToSkip = true,
    this.landscape = false,
    this.containFrom,
    this.containedBackgroundColor = Colors.black,
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

    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.setLooping(widget.loop);
        _controller.play();
      });

    _controller.addListener(_checkFinished);
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
      child: Container(
        color: _contain ? widget.containedBackgroundColor : Colors.black,
        child: Center(
          child: Stack(
            children: [
              // 黑色背景
              Positioned.fill(
                child: Container(
                  color: _contain
                      ? widget.containedBackgroundColor
                      : Colors.black,
                ),
              ),

              if (_ready)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: _contain
                          ? MediaQuery.paddingOf(context)
                          : EdgeInsets.zero,
                      child: FittedBox(
                        fit: _contain ? BoxFit.contain : BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
