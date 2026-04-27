import 'package:flutter/services.dart';

import 'instruction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TemplateInserter — pure, stateless, const-constructible.
//
// Handles the two non-trivial parts of inserting an instruction template:
//
//   1. Line isolation — a template always occupies its own line.
//        If the cursor is not at a blank position, newlines are injected
//        automatically so the template does not corrupt surrounding code.
//
//   2. Cursor placement — after insertion the selection is set to the
//        most useful placeholder inside the template (e.g. the destination
//        register or the immediate value), ready for the user to type over it.
//
// How cursor offsets are calculated
// ───────────────────────────────────
// [InstructionModel.selectionStart] and [selectionEnd] are measured in bytes
// from the first character of the *template string itself* (not the full text).
//
// TemplateInserter adjusts those offsets by:
//   insertAt    — where in the full text the template begins
//   prefixLen   — length of any auto-prepended '\n'
//
// Final selection in the full text:
//   newStart = insertAt + prefixLen + model.selectionStart
//   newEnd   = insertAt + prefixLen + model.selectionEnd
//
// How insertion works with an active selection
// ─────────────────────────────────────────────
// If the current TextEditingValue has a non-collapsed selection the selected
// text is replaced by the template.  The replacement starts at sel.start and
// ends at sel.end (i.e. the selected text is discarded).
// ─────────────────────────────────────────────────────────────────────────────

class TemplateInserter {
  const TemplateInserter();

  /// Returns a new [TextEditingValue] that represents the editor state after
  /// inserting [model.template] at the current cursor / selection.
  TextEditingValue insert({
    required TextEditingValue current,
    required InstructionModel model,
  }) {
    final text = current.text;
    final sel = current.selection;

    // ── Determine the insertion span ──────────────────────────────────────
    // insertAt  = position to start writing
    // removeEnd = position to stop removing (same as insertAt if collapsed)
    final int insertAt;
    final int removeEnd;

    if (sel.isValid) {
      insertAt = sel.start;
      removeEnd = sel.end;
    } else {
      // Fallback: append at the very end if no valid selection exists.
      insertAt = text.length;
      removeEnd = text.length;
    }

    // ── Decide whether auto-newlines are needed ───────────────────────────
    // A leading '\n' is injected when there is non-whitespace text *before*
    // the insertion point on the same line (template must be on its own line).
    final prefix = _needsLeadingNewline(text, insertAt) ? '\n' : '';
    // A trailing '\n' is injected when there is non-whitespace text *after*
    // the replacement end on the same line.
    final suffix = _needsTrailingNewline(text, removeEnd) ? '\n' : '';

    // ── Build the new full text ───────────────────────────────────────────
    final inserted = prefix + model.template + suffix;
    final newText =
        text.substring(0, insertAt) + inserted + text.substring(removeEnd);

    // ── Compute final cursor selection ────────────────────────────────────
    // Offsets within the template are relative to the template start.
    // We shift them by (insertAt + prefix.length).
    final base = insertAt + prefix.length;
    final newStart = base + model.selectionStart;
    final newEnd = base + model.selectionEnd;

    return TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns true if there is non-whitespace text before [pos] on the same
  /// line, indicating the template needs its own line above.
  bool _needsLeadingNewline(String text, int pos) {
    if (pos == 0) return false;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    return text.substring(lineStart, pos).trimLeft().isNotEmpty;
  }

  /// Returns true if there is non-whitespace text after [pos] on the same
  /// line, indicating the template needs its own line below.
  bool _needsTrailingNewline(String text, int pos) {
    if (pos >= text.length) return false;
    final nextNl = text.indexOf('\n', pos);
    final lineEnd = nextNl >= 0 ? nextNl : text.length;
    return text.substring(pos, lineEnd).trimRight().isNotEmpty;
  }
}
