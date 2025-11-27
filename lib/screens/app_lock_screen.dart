import 'package:flutter/material.dart';
import '../services/security_service.dart';
import 'pin_setup_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, this.onUnlock});

  final VoidCallback? onUnlock;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {


  Future<void> _verifyPin() async {
    if (widget.onUnlock != null) {
      // Standalone mode - show PIN dialog directly
      final bool? verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const PinSetupScreen(
          isVerification: true,
        ),
      );
      
      if (verified == true && mounted) {
        widget.onUnlock!();
      }
    } else {
      // Normal mode - use Navigator
      final bool? verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(
            isVerification: true,
          ),
        ),
      );

      if (verified == true && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'App Locked',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please authenticate to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),
                FutureBuilder<bool>(
                  future: SecurityService().isPinEnabled(),
                  builder: (context, snapshot) {
                    final bool pinEnabled = snapshot.data ?? false;

                    if (pinEnabled) {
                      return ElevatedButton.icon(
                        onPressed: _verifyPin,
                        icon: const Icon(Icons.lock),
                        label: const Text('Enter PIN'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

