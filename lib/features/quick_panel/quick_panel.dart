import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../colors/app_colors.dart';
import '../editor/editor_controller.dart';
import 'instruction_button.dart';
import 'instruction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuickPanel — left-side instruction palette.
//
// Layout (top to bottom):
//   • "INSERT" section label
//   • 3×3 grid of InstructionButton widgets
//
// On button press the panel calls EditorController.onInsertTemplate, which
// is a callback registered by CodeEditorPanel.  This keeps QuickPanel
// completely decoupled from the TextEditingController — it knows nothing about
// text editing internals.
// ─────────────────────────────────────────────────────────────────────────────

class QuickPanel extends StatelessWidget {
  const QuickPanel({super.key});

  /// Fixed pixel width consumed by this panel.
  /// [home_screen.dart] uses this constant when computing editorWidth so the
  /// three zones never overlap.
  static const double panelWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: panelWidth,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section header ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: Text(
                'INSERT',
                style: TextStyle(
                  color: AppColors.dimText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ),

            // ── 3 × 3 instruction grid ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: InstructionModel.all
                    .map(
                      (m) => InstructionButton(
                        model: m,
                        onPressed: () => _requestInsert(m),
                      ),
                    )
                    .toList(),
              ),
            ),

            // ── Keyboard shortcut hint ──────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Text(
                'Click to insert\nat cursor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dimText,
                  fontSize: 8,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestInsert(InstructionModel model) {
    Get.find<EditorController>().onInsertTemplate?.call(model);
  }
}
