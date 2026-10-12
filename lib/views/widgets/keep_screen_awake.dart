import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Prevent automatic screen sleep while the gift is in the foreground.
class KeepScreenAwake extends StatefulWidget {
  const KeepScreenAwake({super.key, required this.child, this.setAwake});
  final Widget child;
  final Future<void> Function(bool enabled)? setAwake;

  @override
  State<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends State<KeepScreenAwake>
    with WidgetsBindingObserver {
  Future<void> _pending = Future.value();
  Timer? _refresh;
  bool _active = true;

  void _setAwake(bool enabled) {
    // Serialize changes so a slow enable cannot overtake a background disable.
    _pending = _pending.then((_) async {
      try {
        if (widget.setAwake case final setter?) {
          await setter(enabled);
        } else {
          await WakelockPlus.toggle(enable: enabled);
        }
      } catch (error) {
        debugPrint('Unable to update screen wake lock: $error');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _active =
        state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _setAwake(_active);
    // Video plugins or the OS can release the idle-timer lock while the app
    // remains foregrounded. Reapply it across every screen in the app.
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_active) _setAwake(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs and other temporary foreground interruptions should
    // not release the app's screen lock.
    _active =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _setAwake(_active);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _setAwake(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_active) _setAwake(true);
    return widget.child;
  }
}
