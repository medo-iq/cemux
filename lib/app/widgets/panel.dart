import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';

/// A bordered panel with a compact IDE-style header.
///
/// Must be placed inside a widget that provides bounded height constraints
/// (e.g. [Expanded], [SizedBox] with an explicit height, or similar).
class Panel extends StatelessWidget {
  const Panel({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget child;

  /// Optional widgets placed at the right edge of the header row.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}
