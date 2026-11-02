import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/game_audio.dart';
export '../../services/game_audio.dart' show GameAudio, GameSound;

/// Keeps music alive through a round and releases every player on route exit.
class GameAudioScope extends StatefulWidget {
  const GameAudioScope({super.key, required this.audio, required this.child});
  final GameAudio audio;
  final Widget child;

  static GameAudio? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AudioProvider>()?.audio;

  static void effect(BuildContext context, GameSound sound) {
    final audio = of(context);
    if (audio != null) unawaited(audio.effect(sound));
  }

  @override
  State<GameAudioScope> createState() => _GameAudioScopeState();
}

class _GameAudioScopeState extends State<GameAudioScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    unawaited(widget.audio.start());
    unawaited(widget.audio.effect(GameSound.door));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      widget.audio.setForeground(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AudioProvider(audio: widget.audio, child: widget.child);
}

class _AudioProvider extends InheritedWidget {
  const _AudioProvider({required this.audio, required super.child});
  final GameAudio audio;
  @override
  bool updateShouldNotify(_AudioProvider oldWidget) => audio != oldWidget.audio;
}
