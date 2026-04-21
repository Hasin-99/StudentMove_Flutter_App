import 'package:flutter/material.dart';

import 'motion_specs.dart';

class MotionScaleTap extends StatefulWidget {
  const MotionScaleTap({
    super.key,
    required this.child,
    this.pressedScale = MotionSpecs.pressScaleButton,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<MotionScaleTap> createState() => _MotionScaleTapState();
}

class _MotionScaleTapState extends State<MotionScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        duration: MotionSpecs.quick,
        curve: MotionSpecs.standardCurve,
        scale: _pressed ? widget.pressedScale : 1,
        child: widget.child,
      ),
    );
  }
}

class MotionButtonTap extends StatelessWidget {
  const MotionButtonTap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MotionScaleTap(
      pressedScale: MotionSpecs.pressScaleButton,
      child: child,
    );
  }
}

class MotionFabSmall extends StatelessWidget {
  const MotionFabSmall({
    super.key,
    required this.onPressed,
    required this.child,
    this.heroTag,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Object? heroTag;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return MotionScaleTap(
      pressedScale: MotionSpecs.pressScaleFab,
      child: FloatingActionButton.small(
        onPressed: onPressed,
        heroTag: heroTag,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: child,
      ),
    );
  }
}

class HoverPressCard extends StatefulWidget {
  const HoverPressCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.decoration,
    this.borderRadius = 16,
    this.baseShadow = const [
      BoxShadow(color: Color(0x120F172A), blurRadius: 10, offset: Offset(0, 5)),
    ],
    this.hoverShadow = const [
      BoxShadow(color: Color(0x220F172A), blurRadius: 16, offset: Offset(0, 8)),
    ],
    this.pressedScale = MotionSpecs.pressScaleCard,
    this.splashColor,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final double borderRadius;
  final List<BoxShadow> baseShadow;
  final List<BoxShadow> hoverShadow;
  final double pressedScale;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  State<HoverPressCard> createState() => _HoverPressCardState();
}

class _HoverPressCardState extends State<HoverPressCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: MotionSpecs.quick,
          curve: MotionSpecs.standardCurve,
          scale: _pressed ? widget.pressedScale : 1,
          child: AnimatedContainer(
            duration: MotionSpecs.quick,
            curve: MotionSpecs.standardCurve,
            decoration: widget.decoration.copyWith(
              boxShadow: _hovered ? widget.hoverShadow : widget.baseShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: widget.splashColor,
                highlightColor: widget.highlightColor,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
