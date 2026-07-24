import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Layered 3D brand mark — isometric tilt, depth shadow, and optional float.
class BrandLogo3D extends StatefulWidget {
  const BrandLogo3D({
    super.key,
    this.size = 132,
    this.float = true,
    this.showWordmark = false,
    this.useAsset = true,
  });

  final double size;
  final bool float;
  final bool showWordmark;
  final bool useAsset;

  @override
  State<BrandLogo3D> createState() => _BrandLogo3DState();
}

class _BrandLogo3DState extends State<BrandLogo3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.float) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final lift = widget.float ? lerpDouble(0, -8, t)! : 0.0;
        final tiltX = lerpDouble(0.18, 0.10, t)!;
        final tiltY = lerpDouble(-0.12, 0.12, t)!;
        final shadowSpread = lerpDouble(18, 28, t)!;
        final shadowY = lerpDouble(18, 10, t)!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size + 24,
              height: size + 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft ground shadow for depth.
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: size * 0.72,
                      height: size * 0.16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.22),
                            blurRadius: shadowSpread,
                            spreadRadius: 2,
                            offset: Offset(0, shadowY * 0.15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0022)
                      ..rotateX(tiltX)
                      ..rotateY(tiltY)
                      ..translate(0.0, lift),
                    child: _LogoPlate(
                      size: size,
                      useAsset: widget.useAsset,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showWordmark) ...[
              const SizedBox(height: 10),
              Text(
                'StudentMove',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LogoPlate extends StatelessWidget {
  const _LogoPlate({required this.size, required this.useAsset});

  final double size;
  final bool useAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14A39C),
            Color(0xFF0B6E6A),
            Color(0xFF0B4F4C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(10, 16),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(-4, -6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Specular highlight for plastic/glass 3D feel.
          Align(
            alignment: const Alignment(-0.7, -0.75),
            child: Container(
              width: size * 0.45,
              height: size * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: useAsset
                ? Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                    errorBuilder: (_, __, ___) => const _FallbackGlyph(),
                  )
                : const _FallbackGlyph(),
          ),
          // Side extrusion edge.
          Positioned(
            right: 0,
            top: size * 0.08,
            bottom: size * 0.08,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.black.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackGlyph extends StatelessWidget {
  const _FallbackGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BusGlyphPainter());
  }
}

class _BusGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.22, size.width * 0.76, size.height * 0.48),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(r, paint);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.46),
      Offset(size.width * 0.72, size.height * 0.46),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.78), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.78), size.width * 0.06, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle parallax 3D stage for auth/splash backgrounds.
class Atmosphere3DBackdrop extends StatelessWidget {
  const Atmosphere3DBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.pageAtmosphere)),
        Positioned(
          top: -80,
          right: -40,
          child: Transform.rotate(
            angle: -math.pi / 8,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandLight.withValues(alpha: 0.35),
                    AppColors.brandLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: Transform.rotate(
            angle: math.pi / 7,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.28),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating route “orbits” for depth.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _OrbitPainter()),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.brand.withValues(alpha: 0.12);

    final center = Offset(size.width * 0.72, size.height * 0.22);
    for (var i = 1; i <= 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 90.0 * i,
          height: 36.0 * i,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
