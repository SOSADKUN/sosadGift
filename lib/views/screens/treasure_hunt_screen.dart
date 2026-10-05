import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../config/treasure_hunt_config.dart';
import 'treasure_scanner_screen.dart';

class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen> {
  final _player = AudioPlayer();
  Timer? _arrival;
  StreamSubscription<void>? _audioComplete;
  bool _pickedUp = false;
  bool _voiceArrived = false;
  bool _photoArrived = false;
  bool _playing = false;
  int _voiceIndex = 0;
  bool _loading = false;
  bool _scanning = false;
  bool _completed = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    _audioComplete = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _photoArrived = true;
        });
      }
    });
  }

  void _pickUp() {
    if (_pickedUp) return;
    setState(() => _pickedUp = true);
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
      await _player.pause();
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
    _arrival?.cancel();
    _audioComplete?.cancel();
    _player.dispose();
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
  Widget build(BuildContext context) {
    if (!_pickedUp) {
      return Scaffold(
        backgroundColor: const Color(0xFF241A2D),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '门后，地上有一部手机…',
                  style: TextStyle(color: Color(0xFFECD2A4), fontSize: 22),
                ),
                const SizedBox(height: 70),
                Transform.rotate(
                  angle: -.2,
                  child: Semantics(
                    button: true,
                    label: '捡起手机',
                    child: GestureDetector(
                      onTap: _pickUp,
                      child: Container(
                        width: 130,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10131C),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF998CA8),
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 30,
                              offset: Offset(18, 24),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFFECD2A4),
                              size: 44,
                            ),
                            SizedBox(height: 18),
                            Text(
                              '一条未读消息',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                TextButton(
                  onPressed: _pickUp,
                  child: const Text(
                    '点击捡起手机',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
                  const Center(
                    child: Text(
                      '刚刚',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_voiceArrived) const Text('对方正在输入…'),
                  if (_voiceArrived)
                    _bubble(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('给你留了一段语音，听听看。'),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _loading ? null : _playVoice,
                            icon: Icon(
                              _playing && _voiceIndex == 0
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _loading
                                  ? '正在加载…'
                                  : _playing && _voiceIndex == 0
                                  ? '暂停语音'
                                  : '播放语音',
                            ),
                          ),
                          if (_audioError != null) ...[
                            Text(
                              _audioError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _photoArrived = true),
                              child: const Text('先查看地点线索'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (_photoArrived) ...[
                    _bubble(const Text('去照片里的地方看看。\n接下来，线索藏在现实世界里。')),
                    _bubble(
                      GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(child: _locationPhoto()),
                        ),
                        child: _locationPhoto(),
                      ),
                    ),
                    _bubble(
                      FilledButton.icon(
                        onPressed: _loading ? null : () => _playVoice(1),
                        icon: Icon(
                          _playing && _voiceIndex == 1
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _playing && _voiceIndex == 1 ? '暂停语音' : '播放第二段语音',
                        ),
                      ),
                    ),
                    _bubble(const Text('找到最后的二维码后，回到这里。\n点击发送旁的 ＋，打开相机扫描。')),
                  ],
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
                        child: Text(
                          '跟着线索去寻找吧…',
                          style: TextStyle(color: Colors.grey),
                        ),
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

  Widget _locationPhoto() => Image.asset(
    TreasureHuntConfig.locationPhoto,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => const SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, size: 48),
            SizedBox(height: 12),
            Text('地点照片尚未放入'),
          ],
        ),
      ),
    ),
  );
}
