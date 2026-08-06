import 'package:flutter/material.dart';

class PasswordScreen extends StatefulWidget {
  final String correctCode;
  final VoidCallback onCorrect;

  const PasswordScreen({
    super.key,
    required this.correctCode,
    required this.onCorrect,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _controller = TextEditingController();
  String? _error;

  void _submit() {
    if (_controller.text.trim() == widget.correctCode) {
      widget.onCorrect();
    } else {
      setState(() => _error = '密码不对，再想想～');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '输入密码解锁',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('确认')),
          ],
        ),
      ),
    );
  }
}