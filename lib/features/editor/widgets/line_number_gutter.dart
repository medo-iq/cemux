import 'package:flutter/material.dart';

import '../../../colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LineNumberGutter — fixed-width left strip showing 1-based line numbers.
//
// Enhanced over the original _LineNumbers widget:
//   • Shows a small red dot on lines that have live parse errors.
//   • Different tint/weight for the active PC line vs. an error line.
//   • Keeps scrolling in sync with the main editor via [scrollController].
// ─────────────────────────────────────────────────────────────────────────────

class LineNumberGutter extends StatelessWidget {
  const LineNumberGutter({
    super.key,
    required this.lineCount,
    required this.activeLineIndex, // PC line (null if not executing)
    required this.errorLineIndex, // CPU-reported error line (null if none)
    required this.lineErrors, // live per-line errors from EditorController
    required this.scrollController,
    required this.lineHeight,
    required this.topPadding,
  });

  final int lineCount;
  final int? activeLineIndex;
  final int? errorLineIndex;
  final Map<int, String> lineErrors; // 0-based lineIndex → message
  final ScrollController scrollController;
  final double lineHeight;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: AppColors.surfaceAlt,
      child: ListView.builder(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: topPadding),
        itemExtent: lineHeight,
        itemCount: lineCount,
        itemBuilder: _buildItem,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final isCpuActive = activeLineIndex == index;
    final isCpuError = errorLineIndex == index;
    final hasLiveError = lineErrors.containsKey(index);
    final isHighlit = isCpuActive || isCpuError;

    // Background tint priority: CPU error > live error > CPU active > nothing
    final bgColor = isCpuError
        ? AppColors.danger.withValues(alpha: 0.18)
        : hasLiveError
        ? AppColors.danger.withValues(alpha: 0.10)
        : isCpuActive
        ? AppColors.accent.withValues(alpha: 0.14)
        : Colors.transparent;

    final numColor = isCpuError || hasLiveError
        ? AppColors.danger
        : isCpuActive
        ? AppColors.accent
        : AppColors.dimText;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Error dot — 5 px filled circle on lines with live parse errors.
          SizedBox(
            width: 8,
            child: hasLiveError
                ? Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          // Line number
          Expanded(
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: numColor,
                fontWeight: (isHighlit || hasLiveError)
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
