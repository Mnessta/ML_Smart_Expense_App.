import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isVerification;
  final VoidCallback? onSuccess;

  const PinSetupScreen({
    super.key,
    this.isVerification = false,
    this.onSuccess,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<String> _enteredPin = [];
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
        _errorMessage = '';
      });
      HapticFeedback.lightImpact();

      // Check if PIN is complete
      if (_enteredPin.length == 4) {
        if (widget.isVerification) {
          _verifyPin();
        } else {
          if (!_isConfirming) {
            _confirmPin = _enteredPin.join();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _enteredPin.clear();
                  _isConfirming = true;
                });
              }
            });
          } else {
            _confirmPinEntry();
          }
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = '';
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _verifyPin() async {
    final String pin = _enteredPin.join();
    final bool isValid = await SecurityService().verifyPin(pin);

    if (isValid) {
      HapticFeedback.mediumImpact();
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin.clear();
      });
    }
  }

  Future<void> _confirmPinEntry() async {
    final String pin = _enteredPin.join();
    if (pin == _confirmPin) {
      final bool success = await SecurityService().setPin(pin);
      if (success) {
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to set PIN. Please try again.';
          _enteredPin.clear();
          _isConfirming = false;
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _enteredPin.clear();
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVerification ? 'Enter PIN' : 'Set PIN'),
        automaticallyImplyLeading: !widget.isVerification,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.isVerification ? Icons.lock : Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                widget.isVerification
                    ? 'Enter your PIN'
                    : _isConfirming
                        ? 'Confirm your PIN'
                        : 'Create a 4-digit PIN',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      color: index < _enteredPin.length
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                  );
                }),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Number pad
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _NumberButton('1', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('2', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('3', _onNumberPressed),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _NumberButton('4', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('5', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('6', _onNumberPressed),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _NumberButton('7', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('8', _onNumberPressed),
                      const SizedBox(width: 16),
                      _NumberButton('9', _onNumberPressed),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(width: 80, height: 80),
                      const SizedBox(width: 16),
                      _NumberButton('0', _onNumberPressed),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.backspace),
                        iconSize: 32,
                        onPressed: _onDeletePressed,
                        style: IconButton.styleFrom(
                          fixedSize: const Size(80, 80),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String number;
  final Function(String) onPressed;

  const _NumberButton(this.number, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(number),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(80, 80),
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        number,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}













