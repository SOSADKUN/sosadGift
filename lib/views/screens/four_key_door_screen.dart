import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the journey from the game hub, then holds on the four-lock door.
class FourKeyDoorScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FourKeyDoorScreen({super.key, required this.onComplete});

  @override
  State<FourKeyDoorScreen> createState() => _FourKeyDoorScreenState();
}

class _FourKeyDoorScreenState extends State<FourKeyDoorScreen>
    with SingleTickerProviderStateMixin {
  static const _doorImage = 'assets/photos/bigDoor.png';
  static const _doorVideo = 'assets/videos/bigDoor.mp4';
  static const _imageWidth = 900.0;
  static const _imageHeight = 1600.0;
  static const _holes = [
    Offset(352, 628),
    Offset(549, 628),
    Offset(352, 837),
    Offset(549, 837),
  ];

  late final VideoPlayerController _video = VideoPlayerController.asset(
    _doorVideo,
  )..addListener(_checkVideoEnd);
  late final AnimationController _keyAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  final Set<int> _inserted = {};
  bool _videoReady = false;
  bool _videoFinished = false;
  bool _advancing = false;
  int? _activeHole;

  @override
  void initState() {
    super.initState();
    _startVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_doorImage), context);
  }

  Future<void> _startVideo() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _video.play();
    } catch (_) {
      // If playback is unavailable, keep the interactive door accessible.
      if (mounted) setState(() => _videoFinished = true);
    }
  }

  void _checkVideoEnd() {
    if (!mounted || _videoFinished || !_video.value.isInitialized) return;
    final value = _video.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _video.pause();
      setState(() => _videoFinished = true);
    }
  }

  Future<void> _insertKey(int index) async {
    if (!_videoFinished ||
        _activeHole != null ||
        _inserted.contains(index) ||
        _advancing) {
      return;
    }
    setState(() => _activeHole = index);
    await _keyAnimation.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _inserted.add(index);
      _activeHole = null;
    });
    if (_inserted.length == _holes.length) {
      _advancing = true;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) widget.onComplete();
    }
  }

  @override
  void dispose() {
    _video.removeListener(_checkVideoEnd);
    _video.dispose();
    _keyAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          // Match the positions to Image.asset's BoxFit.cover crop.
          final scale = (width / _imageWidth) > (height / _imageHeight)
              ? width / _imageWidth
              : height / _imageHeight;
          final imageLeft = (width - _imageWidth * scale) / 2;
          final imageTop = (height - _imageHeight * scale) / 2;
          final targetSize = (118 * scale).clamp(48.0, 84.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (_videoFinished)
                Image.asset(_doorImage, fit: BoxFit.cover)
              else if (_videoReady)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _video.value.size.width,
                    height: _video.value.size.height,
                    child: VideoPlayer(_video),
                  ),
                ),
              if (_videoFinished) ...[
                for (var i = 0; i < _holes.length; i++)
                  Positioned(
                    left: imageLeft + _holes[i].dx * scale - targetSize / 2,
                    top: imageTop + _holes[i].dy * scale - targetSize / 2,
                    width: targetSize,
                    height: targetSize,
                    child: _keyhole(i),
                  ),
                Positioned(
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  left: 18,
                  right: 18,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB9382544),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xAAFFE0AF)),
                      ),
                      child: Text(
                        _inserted.length == 4
                            ? '四把钥匙已插入，门正在打开…'
                            : '点击钥匙孔插入钥匙  ${_inserted.length} / 4',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFE9C9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _keyhole(int index) {
    final inserted = _inserted.contains(index);
    final animating = _activeHole == index;
    return Semantics(
      button: !inserted,
      label: '第 ${index + 1} 个钥匙孔${inserted ? '，已插入' : '，点击插入钥匙'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _insertKey(index),
        child: AnimatedBuilder(
          animation: _keyAnimation,
          builder: (context, _) {
            final progress = MediaQuery.disableAnimationsOf(context)
                ? 1.0
                : Curves.easeInOutCubic.transform(_keyAnimation.value);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (inserted)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xDDFFE28B),
                          blurRadius: 22,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                if (inserted || animating)
                  Transform.translate(
                    offset: Offset(
                      animating ? 42 * (1 - progress) : 0,
                      animating ? 28 * (1 - progress) : 0,
                    ),
                    child: Transform.rotate(
                      angle: animating ? -0.8 * (1 - progress) : 0,
                      child: Transform.scale(
                        scale: animating ? 1.25 - 0.25 * progress : 1,
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: const Color(0xFFFFDE7C),
                          size: 32,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 7,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
