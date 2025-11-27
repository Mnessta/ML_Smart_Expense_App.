import 'dart:async';
import 'package:flutter/material.dart';
import '../services/offline_service.dart';

/// Provider for managing connectivity state
class ConnectivityProvider extends ChangeNotifier {
  final OfflineService _offlineService = OfflineService();
  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    _isOnline = await _offlineService.isOnline();
    notifyListeners();
    
    _subscription = _offlineService.connectivityStream.listen((bool online) {
      _isOnline = online;
      notifyListeners();
      
      // Process queue when coming back online
      if (online) {
        _offlineService.processQueue();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

















