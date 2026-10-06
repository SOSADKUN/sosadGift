import 'package:flutter/material.dart';
import 'views/screens/memory_finale_screen.dart';

/// Run with: flutter run -t lib/memory_preview.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const MemoryFinaleScreen(useMockPhotos: true),
    ),
  );
}
