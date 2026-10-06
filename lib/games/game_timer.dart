import 'dart:async';

/// Gameplay time stops while the app is inactive, including delayed feedback.
class GameTimer implements Timer {
  GameTimer(
    Duration duration,
    void Function() callback, {
    required bool Function() isPaused,
  }) : this._(duration, (_) => callback(), false, isPaused);
  GameTimer.periodic(
    Duration duration,
    void Function(Timer) callback, {
    required bool Function() isPaused,
  }) : this._(duration, callback, true, isPaused);

  GameTimer._(this._duration, this._callback, this._periodic, this._isPaused) {
    _timer = Timer.periodic(_step, (_) {
      if (_isPaused()) return;
      _elapsed += _step;
      if (_elapsed < _duration) return;
      _elapsed -= _duration;
      _tick++;
      if (!_periodic) cancel();
      _callback(this);
    });
  }
  static const _step = Duration(milliseconds: 16);
  final Duration _duration;
  final void Function(Timer) _callback;
  final bool _periodic;
  final bool Function() _isPaused;
  late final Timer _timer;
  Duration _elapsed = Duration.zero;
  int _tick = 0;
  @override
  int get tick => _tick;
  @override
  bool get isActive => _timer.isActive;
  @override
  void cancel() => _timer.cancel();
}
