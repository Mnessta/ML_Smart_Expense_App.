import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged async* {
    yield* _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) =>
          results.any((ConnectivityResult r) => r != ConnectivityResult.none),
    );
  }
}































