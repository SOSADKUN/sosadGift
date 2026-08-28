import 'package:flutter/material.dart';
import 'views/app_flow.dart';
import 'controllers/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AppFlow(),
    );
  }
}
