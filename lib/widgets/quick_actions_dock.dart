import 'package:flutter/material.dart';
import 'quick_jump_button.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.heroTag,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? heroTag;
}

class QuickActionsDock extends StatelessWidget {
  const QuickActionsDock({
    super.key,
    required this.actions,
  });

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          QuickJumpButton(
            heroTag: actions[i].heroTag,
            tooltip: actions[i].tooltip,
            icon: actions[i].icon,
            onPressed: actions[i].onPressed,
          ),
          if (i != actions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
