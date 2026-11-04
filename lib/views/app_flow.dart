import 'package:flutter/material.dart';
import '../services/finale_music.dart';
import '../controllers/app_flow_progress.dart';
import '../services/game_audio.dart';
import '../config/game_hub_music_config.dart';
import 'dart:async';

import 'screens/diary_loading_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/diary_open_screen.dart';
import 'screens/story_recap_screen.dart';
import 'screens/gift_intro_screen.dart';
import 'screens/games/game_hub_screen.dart';
import 'screens/password_screen.dart';
import 'screens/gift_reveal_screen.dart';
import 'screens/digital_cake_screen.dart';
import 'screens/four_key_door_screen.dart';
import 'screens/door_opening_screen.dart';
import 'screens/treasure_hunt_screen.dart';
import 'screens/surprise_countdown_screen.dart';
import 'screens/memory_finale_screen.dart';

enum FlowStep {
  splash,
  diaryLoading, // mp4 1: loading screen
  diaryOpen, // mp4 2: diary opens
  storyRecap, // 4-year story: 认识/驾车/bhotel/PD
  giftIntro, // black screen + bgm + popping sentences leading into the games
  gameHub, // 3(4) mini games -> unlocks the code
  fourKeyDoor,
  doorOpening,
  treasureHunt,
  surpriseCountdown,
  password, // enter 0917
  giftReveal, // gift voucher reveal
  memoryFinale,
  digitalCake, // close eyes, blow candle
}

const List<FlowStep> kFlowOrder = [
  FlowStep.splash,
  FlowStep.diaryLoading,
  FlowStep.diaryOpen,
  FlowStep.storyRecap,
  FlowStep.giftIntro,
  FlowStep.gameHub,
  FlowStep.fourKeyDoor,
  FlowStep.doorOpening,
  FlowStep.treasureHunt,
  FlowStep.surpriseCountdown,
  FlowStep.digitalCake,
  FlowStep.memoryFinale,
];

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  final _progress = AppFlowProgress(kFlowOrder);
  int get _index => _progress.index;
  final _finaleMusic = FinaleMusic();
  final _hubAudio = GameAudio(
    GameHubMusicConfig.asset,
    musicVolume: GameHubMusicConfig.volume,
  );

  @override
  void dispose() {
    _finaleMusic.dispose();
    unawaited(_hubAudio.dispose());
    super.dispose();
  }

  void _next(FlowStep source) {
    if (!mounted || !_progress.complete(source)) return;
    if (source == FlowStep.gameHub) unawaited(_hubAudio.dispose());
    setState(() {});
  }

  Widget _build(FlowStep step) {
    switch (step) {
      case FlowStep.splash:
        return SplashScreen(onComplete: () => _next(step));
      case FlowStep.diaryLoading:
        return DiaryLoadingScreen(onComplete: () => _next(step));
      case FlowStep.diaryOpen:
        return DiaryOpenScreen(onComplete: () => _next(step));
      case FlowStep.storyRecap:
        return StoryRecapScreen(onComplete: () => _next(step));
      case FlowStep.giftIntro:
        return GiftIntroScreen(
          onComplete: () => _next(step),
          audio: _hubAudio,
          chorusStart: GameHubMusicConfig.chorusStart,
        );
      case FlowStep.gameHub:
        return GameHubScreen(
          onAllGamesComplete: () => _next(step),
          audio: _hubAudio,
        );
      case FlowStep.fourKeyDoor:
        return FourKeyDoorScreen(onComplete: () => _next(step));
      case FlowStep.doorOpening:
        return DoorOpeningScreen(onComplete: () => _next(step));
      case FlowStep.treasureHunt:
        return TreasureHuntScreen(onComplete: () => _next(step));
      case FlowStep.surpriseCountdown:
        return SurpriseCountdownScreen(onComplete: () => _next(step));
      case FlowStep.password:
        return PasswordScreen(
          correctCode: '0917',
          onCorrect: () => _next(step),
        );
      case FlowStep.giftReveal:
        return GiftRevealScreen(onComplete: () => _next(step));
      case FlowStep.digitalCake:
        return DigitalCakeScreen(
          onComplete: () => _next(step),
          finaleMusic: _finaleMusic,
        );
      case FlowStep.memoryFinale:
        return MemoryFinaleScreen(music: _finaleMusic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteringHub = kFlowOrder[_index] == FlowStep.gameHub;
    final enteringOpening = kFlowOrder[_index] == FlowStep.doorOpening;
    final enteringHunt = kFlowOrder[_index] == FlowStep.treasureHunt;
    final enteringDoor = kFlowOrder[_index] == FlowStep.fourKeyDoor;
    final enteringDiary = kFlowOrder[_index] == FlowStep.storyRecap;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: Duration(
        milliseconds: enteringDoor || enteringOpening || enteringHunt
            ? 0
            : reducedMotion
            ? 200
            : enteringHub
            ? 1000
            : enteringDiary
            ? 500
            : 350,
      ),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final isDiary =
            child.key == ValueKey(kFlowOrder.indexOf(FlowStep.storyRecap));
        if (enteringDiary && isDiary) {
          // Reveal the diary immediately through a brief white dissolve.
          final reveal = animation.drive(
            CurveTween(curve: Curves.easeOut),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              IgnorePointer(
                child: FadeTransition(
                  opacity: ReverseAnimation(reveal),
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ],
          );
        }
        final fade = FadeTransition(opacity: animation, child: child);
        if (!enteringHub || reducedMotion) return fade;
        final isHub =
            child.key == ValueKey(kFlowOrder.indexOf(FlowStep.gameHub));
        if (!isHub) return fade;
        // Gently reveal the lobby on the chorus without restarting its audio.
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .018),
            end: Offset.zero,
          ).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.025, end: 1).animate(animation),
            child: fade,
          ),
        );
      },
      child: Container(
        key: ValueKey(_index),
        color: Colors.black,
        child: _build(kFlowOrder[_index]),
      ),
    );
  }
}
