import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_unlock_policy.dart';

/// Do not construct the story or start its audio until access is granted.
class AppUnlockScreen extends StatefulWidget {
  const AppUnlockScreen({
    super.key,
    required this.builder,
    this.now,
    this.verifyPassword = AppUnlockPolicy.verifyAdminPassword,
  });
  final WidgetBuilder builder;
  final DateTime Function()? now;
  final Future<bool> Function(String) verifyPassword;

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen>
    with WidgetsBindingObserver {
  final _password = TextEditingController();
  Timer? _timer;
  bool _unlocked = false;
  bool _admin = false;
  bool _checking = false;
  String? _error;
  Widget? _content;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlocked = AppUnlockPolicy.isOpen(widget.now?.call() ?? DateTime.now());
    if (!_unlocked) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkTime());
    }
  }

  void _checkTime() {
    if (!mounted || _unlocked) return;
    if (AppUnlockPolicy.isOpen(widget.now?.call() ?? DateTime.now())) {
      _grantAccess();
    }
  }

  void _grantAccess() {
    _timer?.cancel();
    _password.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _unlocked = true);
  }

  Future<void> _submit() async {
    if (_checking || _unlocked || _password.text.isEmpty) return;
    final password = _password.text;
    _password.clear();
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final valid = await widget.verifyPassword(password);
      if (!mounted || _unlocked) return;
      if (valid) {
        _grantAccess();
      } else {
        // Slow repeated guesses without saving credentials or bypass state.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted && !_unlocked) {
          setState(() => _error = '密码不正确，请再试一次');
        }
      }
    } catch (_) {
      if (mounted && !_unlocked) {
        setState(() => _error = '验证暂时失败，请再试一次');
      }
    } finally {
      if (mounted && !_unlocked) setState(() => _checking = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return _content ??= widget.builder(context);
    const gold = Color(0xFFECD2A4);
    return Scaffold(
      backgroundColor: const Color(0xFF160F23),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.35),
            radius: 1.2,
            colors: [Color(0xFF38213D), Color(0xFF160F23)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gold.withValues(alpha: .06),
                        border: Border.all(color: gold.withValues(alpha: .22)),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: gold,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'A SURPRISE WORTH WAITING FOR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '此 App 已锁定',
                      style: TextStyle(color: Color(0xFFF9EDE5), fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '为妳准备的惊喜，还没到揭晓的时候 ♡',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFBFAEC8), height: 1.8),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold.withValues(alpha: .18)),
                        color: Colors.white.withValues(alpha: .025),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '开启时间 · 马来西亚',
                            style: TextStyle(
                              color: Color(0xFFBFAEC8),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '2026 年 11 月 7 日',
                            style: TextStyle(color: gold, fontSize: 21),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '晚上 11:30',
                            style: TextStyle(color: gold, fontSize: 26),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _checking
                          ? null
                          : () => setState(() => _admin = !_admin),
                      child: const Text(
                        '管理员入口',
                        style: TextStyle(color: Color(0xFFBFAEC8)),
                      ),
                    ),
                    if (_admin) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _password,
                        enabled: !_checking,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '管理员密码',
                          labelStyle: const TextStyle(color: Color(0xFFBFAEC8)),
                          errorText: _error,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _checking ? null : _submit,
                        child: Text(_checking ? '验证中…' : '解锁'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
