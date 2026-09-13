import 'package:flutter/material.dart';

import 'screens/diary_loading_screen.dart';
import 'screens/diary_open_screen.dart';
import 'screens/story_recap_screen.dart';
import 'screens/gift_intro_screen.dart';
import 'screens/games/game_hub_screen.dart';
import 'screens/password_screen.dart';
import 'screens/gift_reveal_screen.dart';
import 'screens/digital_cake_screen.dart';

enum FlowStep {
  diaryLoading, // mp4 1: loading screen
  diaryOpen, // mp4 2: diary opens
  storyRecap, // 4-year story: 认识/驾车/bhotel/PD
  giftIntro, // black screen + bgm + popping sentences leading into the games
  gameHub, // 3(4) mini games -> unlocks the code
  password, // enter 0917
  giftReveal, // gift voucher reveal
  digitalCake, // close eyes, blow candle
}

const List<FlowStep> kFlowOrder = [
  FlowStep.diaryLoading,
  FlowStep.diaryOpen,
  FlowStep.storyRecap,
  FlowStep.giftIntro,
  FlowStep.gameHub,
  FlowStep.password,
  FlowStep.giftReveal,
  FlowStep.digitalCake,
];

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  int _index = 0;

  void _next() {
    if (_index < kFlowOrder.length - 1) {
      setState(() => _index++);
    }
  }

  // Handy if you ever want a "skip for testing" button during dev.
  void _jumpTo(FlowStep step) {
    setState(() => _index = kFlowOrder.indexOf(step));
  }

  Widget _build(FlowStep step) {
    switch (step) {
      case FlowStep.diaryLoading:
        return DiaryLoadingScreen(onComplete: _next);
      case FlowStep.diaryOpen:
        return DiaryOpenScreen(onComplete: _next);
      case FlowStep.storyRecap:
        return StoryRecapScreen(onComplete: _next);
      case FlowStep.giftIntro:
        return GiftIntroScreen(onComplete: _next);
      case FlowStep.gameHub:
        return GameHubScreen(onAllGamesComplete: _next);
      case FlowStep.password:
        return PasswordScreen(correctCode: '0917', onCorrect: _next);
      case FlowStep.giftReveal:
        return GiftRevealScreen(onComplete: _next);
      case FlowStep.digitalCake:
        return const DigitalCakeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteringHub = kFlowOrder[_index] == FlowStep.gameHub;
    final enteringDiary = kFlowOrder[_index] == FlowStep.storyRecap;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: Duration(
        milliseconds: reducedMotion
            ? 200
            : enteringDiary
            ? 1800
            : enteringHub
            ? 1400
            : 350,
      ),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final isDiary =
            child.key == ValueKey(kFlowOrder.indexOf(FlowStep.storyRecap));
        if (enteringDiary && isDiary) {
          // The new diary covers the outgoing video immediately. Its white
          // veil holds briefly, then dissolves to reveal the page underneath.
          final reveal = animation.drive(
            CurveTween(curve: const Interval(0.15, 1, curve: Curves.easeOut)),
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
        return ScaleTransition(
          scale: Tween<double>(
            begin: isHub ? 1.08 : 1.15,
            end: 1,
          ).animate(animation),
          child: fade,
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
