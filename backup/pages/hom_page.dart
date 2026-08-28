import 'package:flutter/material.dart';
import 'package:gift/views/app_flow.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppFlow()),
            );
          },
          child: const Text('Start'),
        ),
      ),
    );
  }
}
