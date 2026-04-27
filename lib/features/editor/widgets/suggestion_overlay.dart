import 'package:flutter/material.dart';

import '../../../colors/app_colors.dart';
import '../editor_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionOverlay — floating autocomplete dropdown.
//
// Rendered inside the editor's Stack, positioned just below the cursor line.
// Supports:
//   • Mouse click to accept
//   • Arrow key navigation via parent's EditorController.moveSuggestion
//   • Animated selection highlight
// ─────────────────────────────────────────────────────────────────────────────

class SuggestionOverlay extends StatelessWidget {
  const SuggestionOverlay({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDismiss,
  });

  final List<SuggestionItem> items;
  final int selectedIndex;
  final ValueChanged<SuggestionItem> onSelect;
  final VoidCallback onDismiss;

  static const double _itemHeight = 36.0;
  static const double _maxHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final listHeight = (items.length * _itemHeight).clamp(0.0, _maxHeight);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: listHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemExtent: _itemHeight,
            itemBuilder: (_, i) => _SuggestionRow(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(items[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single row inside the overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SuggestionItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isInstr = item.kind == SuggestionKind.instruction;
    final badgeColor = isInstr ? AppColors.accent : AppColors.accentBlue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: selected
            ? AppColors.accent.withValues(alpha: 0.16)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // Kind badge: "I" for instruction, "R" for register
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isInstr ? 'I' : 'R',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const SizedBox(width: 9),

            // Label
            Text(
              item.label,
              style: TextStyle(
                color: selected ? AppColors.text : AppColors.text,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            const SizedBox(width: 10),

            // Detail (dimmed, truncated)
            Expanded(
              child: Text(
                item.detail,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dimText,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
