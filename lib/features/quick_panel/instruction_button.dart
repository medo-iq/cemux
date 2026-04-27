import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import 'instruction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InstructionButton — a single square button in the quick-insert grid.
//
// Visual feedback:
//   • Subtle background tint at rest.
//   • Brighter border + background on hover.
//   • Scale-down (0.94×) on press for tactile feel.
// ─────────────────────────────────────────────────────────────────────────────

class InstructionButton extends StatefulWidget {
  const InstructionButton({
    super.key,
    required this.model,
    required this.onPressed,
  });

  final InstructionModel model;
  final VoidCallback onPressed;

  @override
  State<InstructionButton> createState() => _InstructionButtonState();
}

class _InstructionButtonState extends State<InstructionButton> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _pressing;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressing = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressing ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.surfaceElevated,
              border: Border.all(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.50)
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mnemonic — bold monospace, colour-coded like editor
                Text(
                  widget.model.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppColors.accent : AppColors.text,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                // Operand hint subtitle
                Text(
                  widget.model.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dimText,
                    fontSize: 7,
                    height: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
