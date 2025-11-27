import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({super.key, required this.onPressed, required this.child, this.isLoading = false});

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null || widget.isLoading
          ? null
          : (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
              _controller.forward();
            },
      onTapUp: widget.onPressed == null || widget.isLoading
          ? null
          : (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.onPressed == null || widget.isLoading
                ? LinearGradient(colors: <Color>[Colors.grey.shade400, Colors.grey.shade500])
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isPressed
                ? <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: (widget.onPressed == null || widget.isLoading ? Colors.grey : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}






