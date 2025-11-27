import 'package:flutter/material.dart';
import '../services/security_service.dart';

class BiometricSetupDialog extends StatefulWidget {
  const BiometricSetupDialog({super.key});

  @override
  State<BiometricSetupDialog> createState() => _BiometricSetupDialogState();
}

class _BiometricSetupDialogState extends State<BiometricSetupDialog> {
  String _status = 'Checking device capabilities...';
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _biometricType;
  bool? _isFingerprint;
  bool _needsDeviceSetup = false;

  @override
  void initState() {
    super.initState();
    _checkAndSetup();
  }

  Future<void> _checkAndSetup() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _status = 'Checking device capabilities...';
    });

    // Step 1: Check device support
    final bool isDeviceSupported = await SecurityService().isBiometricAvailable();
    if (!isDeviceSupported) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Your device does not support biometric authentication.';
      });
      return;
    }

    setState(() {
      _status = 'Checking for fingerprint sensor...';
    });

    // Step 2: Check if fingerprint is available
    final bool isFingerprintAvailable = await SecurityService().isFingerprintAvailable();
    final String biometricType = await SecurityService().getBiometricTypeName();
    final bool hasEnrolled = await SecurityService().hasBiometricsEnrolled();

    if (!hasEnrolled) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _needsDeviceSetup = true;
        _errorMessage = 'Please set up a fingerprint or face unlock in your device Settings first.\n\nGo to: Settings → Security → Fingerprint/Face unlock';
      });
      return;
    }

    setState(() {
      _biometricType = biometricType;
      _isFingerprint = isFingerprintAvailable;
      _status = isFingerprintAvailable
          ? 'Place your finger on the fingerprint sensor...'
          : 'Authenticate with ${biometricType.toLowerCase()}...';
    });

    // Step 3: Authenticate to enable
    final Map<String, dynamic> result = await SecurityService().setupBiometricLock();

    if (result['success'] == true) {
      setState(() {
        _isLoading = false;
        _status = 'Biometric lock enabled successfully!';
      });
      
      // Wait a moment to show success, then close
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = result['error'] ?? 'Failed to enable biometric lock.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Icon
            Icon(
              _isFingerprint == true
                  ? Icons.fingerprint
                  : _biometricType?.toLowerCase().contains('face') == true
                      ? Icons.face
                      : Icons.security,
              size: 64,
              color: _hasError ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              _hasError ? 'Setup Failed' : 'Setting Up Biometric Lock',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status/Error message
            if (_isLoading)
              Column(
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else if (_hasError)
              Column(
                children: <Widget>[
                  Text(
                    _errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  if (_needsDeviceSetup) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Go to Device Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              )
            else
              Column(
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            if (!_isLoading && _hasError)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  if (!_needsDeviceSetup)
                    ElevatedButton(
                      onPressed: _checkAndSetup,
                      child: const Text('Try Again'),
                    ),
                ],
              )
            else if (!_isLoading && !_hasError)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              ),
          ],
        ),
      ),
    );
  }
}

