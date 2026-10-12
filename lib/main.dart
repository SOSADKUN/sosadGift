import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'views/app_flow.dart';
import 'views/widgets/keep_screen_awake.dart';
import 'controllers/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the screen awake even while startup services are loading.
  try {
    await WakelockPlus.enable();
  } catch (error) {
    debugPrint('Initial screen wake lock unavailable: $error');
  }

  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Birthday 🎂',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      // Also style routes and overlays that sit outside a Scaffold/Material.
      builder: (context, child) => KeepScreenAwake(
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            inherit: false,
            decoration: TextDecoration.none,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const AppFlow(),
    );
  }
}
