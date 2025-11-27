import 'dart:async';

/// Performance utilities for optimizing app performance
class PerformanceUtils {
  /// Batch process items to avoid blocking UI
  static Future<void> batchProcess<T>(
    List<T> items,
    Future<void> Function(T) processor, {
    int batchSize = 10,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final List<T> batch = items.skip(i).take(batchSize).toList();
      
      await Future.wait(
        batch.map((T item) => processor(item)),
      );
      
      if (i + batchSize < items.length) {
        await Future<void>.delayed(delayBetweenBatches);
      }
    }
  }

  /// Throttle function calls
  static Function throttle(
    Function func, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    bool isThrottled = false;

    return () {
      if (isThrottled) return;
      
      isThrottled = true;
      func();
      
      timer?.cancel();
      timer = Timer(delay, () {
        isThrottled = false;
      });
    };
  }

  /// Measure execution time
  static Future<T> measureTime<T>(
    Future<T> Function() function,
    void Function(Duration) onComplete,
  ) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final T result = await function();
    stopwatch.stop();
    onComplete(stopwatch.elapsed);
    return result;
  }
}

/// Memory-efficient list pagination
class PaginatedList<T> {
  PaginatedList({
    required this.pageSize,
    required this.loader,
  });

  final int pageSize;
  final Future<List<T>> Function(int page, int pageSize) loader;

  final List<T> _items = <T>[];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  List<T> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    try {
      final List<T> newItems = await loader(_currentPage, pageSize);
      if (newItems.length < pageSize) {
        _hasMore = false;
      }
      _items.addAll(newItems);
      _currentPage++;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    await loadNextPage();
  }
}

















