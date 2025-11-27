import 'dart:async';

/// Utility class for debouncing function calls
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Debouncer for search input
class SearchDebouncer {
  SearchDebouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void debounce(String query, void Function(String) callback) {
    _timer?.cancel();
    _timer = Timer(delay, () => callback(query));
  }

  void dispose() {
    _timer?.cancel();
  }
}

















