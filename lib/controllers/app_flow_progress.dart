/// Accept completion only from the active page; late callbacks cannot skip it.
class AppFlowProgress<T> {
  AppFlowProgress(this.steps) : assert(steps.isNotEmpty);
  final List<T> steps;
  int _index = 0;
  int get index => _index;
  T get current => steps[_index];

  bool complete(T source) {
    if (source != current || _index >= steps.length - 1) return false;
    _index++;
    return true;
  }
}
