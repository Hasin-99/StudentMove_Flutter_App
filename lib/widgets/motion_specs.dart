import 'package:flutter/material.dart';

abstract final class MotionSpecs {
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration emphasized = Duration(milliseconds: 320);
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuart;
  static const double pressScaleCard = 0.988;
  static const double pressScaleButton = 0.992;
  static const double pressScaleFab = 0.985;
}

class AnimatedSection extends StatefulWidget {
  const AnimatedSection({
    super.key,
    required this.child,
    this.order = 0,
    this.offsetY = 10,
    this.duration = MotionSpecs.normal,
  });

  final Widget child;
  final int order;
  final double offsetY;
  final Duration duration;

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: MotionSpecs.standardCurve,
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionSpecs.standardCurve),
    );
    _play();
  }

  Future<void> _play() async {
    if (!mounted) return;
    final disableAnimations =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (disableAnimations) {
      _controller.value = 1;
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: 40 * widget.order));
    if (!mounted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
