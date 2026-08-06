import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/video_player_widget.dart';

class GenshinVideoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GenshinVideoScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<GenshinVideoScreen> createState() => _GenshinVideoScreenState();
}

class _GenshinVideoScreenState extends State<GenshinVideoScreen> {
  @override
  void initState() {
    super.initState();

    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 隐藏状态栏（可选）
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    // 恢复直屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoPlayerWidget(
        assetPath: 'assets/videos/genshin_intro.mp4',
        landscape: true,
        onComplete: widget.onComplete,
      ),
    );
  }
}