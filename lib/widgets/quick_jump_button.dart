import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickJumpButton extends StatelessWidget {
  const QuickJumpButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.heroTag,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.brand,
      child: Icon(icon),
    );
  }
}
