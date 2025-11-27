import 'package:flutter/material.dart';

class GlowSnakeBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double thickness;
  final Color glowColor;
  final bool enableRotation;
  final bool enablePulse;
  final double snakeSpeed; // Higher = slower

  const GlowSnakeBorder({
    super.key,
    required this.child,
    this.borderRadius = 25,
    this.thickness = 4,
    this.glowColor = Colors.blueAccent,
    this.enableRotation = true,
    this.enablePulse = true,
    this.snakeSpeed = 5.0, // 5 seconds for full cycle
  });

  @override
  State<GlowSnakeBorder> createState() => _GlowSnakeBorderState();
}

class _GlowSnakeBorderState extends State<GlowSnakeBorder>
    with TickerProviderStateMixin {
  late AnimationController _snakeController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Snake animation controller (slower)
    _snakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.snakeSpeed * 1000).round()),
    )..repeat();

    // Rotation controller (slow rotation)
    if (widget.enableRotation) {
      _rotationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20), // Slow rotation
      )..repeat();
    }

    // Pulse controller (outer glow pulse)
    if (widget.enablePulse) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _snakeController.dispose();
    if (widget.enableRotation) {
      _rotationController.dispose();
    }
    if (widget.enablePulse) {
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _snakeController,
        if (widget.enableRotation) _rotationController,
        if (widget.enablePulse) _pulseController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: GlowSnakePainter(
            progress: _snakeController.value,
            glowColor: widget.glowColor,
            thickness: widget.thickness,
            borderRadius: widget.borderRadius,
            pulseOpacity: widget.enablePulse
                ? _pulseController.value * 0.3 + 0.7
                : 1.0,
            rotationAngle: widget.enableRotation
                ? _rotationController.value * 2 * 3.14159 * 0.05
                : 0.0,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class GlowSnakePainter extends CustomPainter {
  final double progress;
  final double thickness;
  final double borderRadius;
  final Color glowColor;
  final double pulseOpacity;
  final double rotationAngle;

  GlowSnakePainter({
    required this.progress,
    required this.glowColor,
    required this.thickness,
    required this.borderRadius,
    this.pulseOpacity = 1.0,
    this.rotationAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Apply rotation if needed
    if (rotationAngle != 0.0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(rotationAngle);
      canvas.translate(-size.width / 2, -size.height / 2);
    }
    
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      );

    final metric = path.computeMetrics().first;
    final length = metric.length;

    double start = length * progress;
    double end = start + 100; // size of moving snake light (increased for better visibility)

    if (end > length) {
      end -= length;
    }

    // Outer glow (pulsing effect) - increased strength
    final outerGlowPaint = Paint()
      ..strokeWidth = thickness + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20) // Stronger outer glow
      ..color =
          glowColor.withValues(alpha: 0.7 * pulseOpacity); // Reduced transparency

    Path outerGlowPath;
    if (start < end) {
      outerGlowPath = metric.extractPath(start, end);
    } else {
      outerGlowPath = Path()
        ..addPath(metric.extractPath(start, length), Offset.zero)
        ..addPath(metric.extractPath(0, end), Offset.zero);
    }

    // Draw outer glow
    canvas.drawPath(outerGlowPath, outerGlowPaint);

    // Main glowing snake - increased strength
    final glowPaint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15) // Stronger glow effect
      ..shader = LinearGradient(
        colors: [
          glowColor.withValues(alpha: 1.0 * pulseOpacity), // Full opacity, no transparency
          glowColor.withValues(alpha: 0.4 * pulseOpacity), // Reduced fade-out
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    Path glowingPath;
    if (start < end) {
      glowingPath = metric.extractPath(start, end);
    } else {
      glowingPath = Path()
        ..addPath(metric.extractPath(start, length), Offset.zero)
        ..addPath(metric.extractPath(0, end), Offset.zero);
    }

    // Draw main snake
    canvas.drawPath(glowingPath, glowPaint);
    
    // Restore canvas if rotated
    if (rotationAngle != 0.0) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GlowSnakePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      pulseOpacity != oldDelegate.pulseOpacity ||
      rotationAngle != oldDelegate.rotationAngle;
}

