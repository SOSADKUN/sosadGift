import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../config/treasure_hunt_config.dart';
import 'treasure_scanner_screen.dart';
import '../widgets/found_phone_frame.dart';
import '../widgets/found_phone_lock_screen.dart';
import '../widgets/phone_floor_scene.dart';

class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with SingleTickerProviderStateMixin {
  AudioPlayer? _voicePlayer;
  AudioPlayer get _player => _voicePlayer ??= _createPlayer();
  Timer? _arrival;
  Timer? _secondVoiceArrival;
  StreamSubscription<void>? _audioComplete;
  bool _pickedUp = false;
  bool _unlocked = false;
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _voiceArrived = false;
  bool _photoArrived = false;
  bool _secondVoiceArrived = false;
  bool _playing = false;
  int _voiceIndex = 0;
  bool _loading = false;
  bool _scanning = false;
  bool _completed = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    _reveal.forward();
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _audioComplete = player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final revealPhoto = _voiceIndex == 0 && !_photoArrived;
      setState(() {
        _playing = false;
        if (revealPhoto) _photoArrived = true;
      });
      if (revealPhoto) {
        _secondVoiceArrival = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _secondVoiceArrived = true);
        });
      }
    });
    return player;
  }

  void _pickUp() {
    if (_pickedUp || _reveal.value < .85) return;
    setState(() => _pickedUp = true);
  }

  void _unlockPhone() {
    if (_unlocked) return;
    setState(() => _unlocked = true);
    _arrival = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _voiceArrived = true);
    });
  }

  Future<void> _playVoice([int index = 0]) async {
    if (_loading) return;
    if (_playing && _voiceIndex == index) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() {
      _loading = true;
      _audioError = null;
    });
    try {
      if (_voiceIndex == index && _player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        _voiceIndex = index;
        await _player.play(AssetSource(TreasureHuntConfig.voiceAssets[index]));
      }
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _audioError = '语音暂时无法播放，请重试。';
          _playing = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    if (_scanning || _completed) return;
    _scanning = true;
    try {
      await _voicePlayer?.pause();
    } catch (_) {
      // Scanning remains available if the optional audio is unavailable.
    }
    if (!mounted) return;
    setState(() => _playing = false);
    final found = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TreasureScannerScreen()),
    );
    _scanning = false;
    if (!mounted || found != true || _completed) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _arrival?.cancel();
    _secondVoiceArrival?.cancel();
    _audioComplete?.cancel();
    _voicePlayer?.dispose();
    super.dispose();
  }

  Widget _bubble(Widget child) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16, right: 36),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pickedUp ? const Color(0xFF211B28) : Colors.white,
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      child: !_pickedUp
          ? Stack(
              key: const ValueKey('floor-scene'),
              fit: StackFit.expand,
              children: [
                PhoneFloorScene(onPickUp: _pickUp),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (_, _) {
                      final visible = Curves.easeInOutCubic.transform(
                        ((_reveal.value - .12) / .88).clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: 1 - visible,
                        child: const ColoredBox(
                          key: ValueKey('room-white-veil'),
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : SafeArea(
              key: const ValueKey('picked-up-phone'),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: FoundPhoneFrame(
                      dark: !_unlocked,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _unlocked
                            ? _chatScreen()
                            : FoundPhoneLockScreen(onUnlocked: _unlockPhone),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _chatScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE8),
      appBar: AppBar(
        title: const Text('神秘联系人'),
        backgroundColor: const Color(0xFFF1EDE8),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  if (_voiceArrived) _voiceMessage(0),
                  if (_photoArrived)
                    _bubble(
                      GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(child: _locationPhoto()),
                        ),
                        child: _locationPhoto(),
                      ),
                    ),
                  if (_secondVoiceArrived) _voiceMessage(1),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(height: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '扫描找到的二维码',
                    onPressed: _photoArrived ? _scan : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Text('发送', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceMessage(int index) => _bubble(
    SizedBox(
      width: 180,
      child: InkWell(
        key: ValueKey('hunt-voice-$index'),
        borderRadius: BorderRadius.circular(12),
        onTap: _loading ? null : () => _playVoice(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (_loading && _voiceIndex == index)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _audioError != null && _voiceIndex == index
                      ? Icons.refresh
                      : _playing && _voiceIndex == index
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              const SizedBox(width: 16),
              const Expanded(child: Icon(Icons.graphic_eq, size: 36)),
              const Icon(Icons.volume_up_outlined, size: 20),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _locationPhoto() => Image.asset(
    TreasureHuntConfig.locationPhoto,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => const SizedBox(
      height: 180,
      child: Center(child: Icon(Icons.photo_outlined, size: 48)),
    ),
  );
}
