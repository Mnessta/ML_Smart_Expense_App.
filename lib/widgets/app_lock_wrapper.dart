import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../screens/app_lock_screen.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Check if we should lock the app when resuming
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    final bool shouldLock = await SecurityService().shouldLockApp();
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        _isLocked = shouldLock;
      });
    }
  }

  void _unlockApp() {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppLockScreen(
          onUnlock: _unlockApp,
        ),
      );
    }

    return widget.child;
  }
}

