import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/nada_theme.dart';

/// A very quiet pool of light behind the running session.
///
/// Two low-alpha radial gradients drift on Lissajous curves. The painter is
/// isolated in a [RepaintBoundary] and repaints through the animation's
/// [Listenable], so no widget rebuilds and no layout work happen per frame.
/// There is no blur, image or shader asset involved.
class NadaAurora extends StatefulWidget {
  const NadaAurora({super.key, required this.active});

  /// The glow freezes while the session is paused.
  final bool active;

  @override
  State<NadaAurora> createState() => _NadaAuroraState();
}

class _NadaAuroraState extends State<NadaAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncMotion();
  }

  @override
  void didUpdateWidget(NadaAurora oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.active && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _NadaAuroraPainter(
            animation: _reduceMotion ? null : _controller,
            fallback: 0.18,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _NadaAuroraPainter extends CustomPainter {
  _NadaAuroraPainter({this.animation, required this.fallback})
    : super(repaint: animation);

  final Animation<double>? animation;
  final double fallback;

  double get _time => animation?.value ?? fallback;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final phase = _time * math.pi * 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final centerA = Offset(
      width * (0.31 + 0.12 * math.sin(phase * 0.90)),
      height * (0.38 + 0.09 * math.cos(phase * 0.70 + 0.7)),
    );
    final radiusA = width * (0.67 + 0.10 * math.sin(phase * 0.60 + 0.3));
    final alphaA = 0.075 + 0.025 * math.sin(phase * 3.0 + 1.1);
    _glow(canvas, size, centerA, radiusA, alphaA, paint);

    final centerB = Offset(
      width * (0.70 + 0.10 * math.cos(phase * 0.80 + 2.1)),
      height * (0.60 + 0.08 * math.sin(phase * 0.90 + 1.2)),
    );
    final radiusB = width * (0.52 + 0.08 * math.cos(phase * 0.70 + 0.5));
    final alphaB = 0.045 + 0.015 * math.cos(phase * 2.5 + 0.2);
    _glow(canvas, size, centerB, radiusB, alphaB, paint);
  }

  void _glow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double alpha,
    Paint paint,
  ) {
    final transparent = NadaColors.bone.withValues(alpha: 0);
    paint.shader = RadialGradient(
      colors: [
        NadaColors.bone.withValues(alpha: alpha),
        NadaColors.bone.withValues(alpha: alpha * 0.35),
        transparent,
      ],
      stops: const [0, 0.52, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_NadaAuroraPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.fallback != fallback;
}
