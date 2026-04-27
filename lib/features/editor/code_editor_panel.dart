import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/controllers/cpu_controller.dart';
import '../../app/widgets/panel.dart';
import '../../colors/app_colors.dart';
import '../quick_panel/instruction_model.dart';
import '../quick_panel/template_inserter.dart';
import 'editor_controller.dart';
import 'editor_state.dart';
import 'syntax_highlighter.dart';
import 'widgets/line_number_gutter.dart';
import 'widgets/suggestion_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CodeEditorPanel — Mini Assembly IDE
//
// Features
//   ✓ Syntax highlighting   (instructions / registers / immediates / comments)
//   ✓ Line number gutter    (with error-dot indicators)
//   ✓ PC line highlight     (synced to CpuController.currentLineIndex)
//   ✓ Error line highlight  (CPU parse error + live validation)
//   ✓ Live error detection  (debounced, per-line, shown in gutter + hint bar)
//   ✓ Auto-complete overlay (context-aware: instruction → register → immediate)
//   ✓ Keyboard navigation   (↑ ↓ Enter/Tab accept, ESC dismiss)
//   ✓ Ctrl+Space            (manually trigger suggestions)
//   ✓ Ctrl/Cmd+Enter        (load program)
//   ✓ Auto-format           (normalises known tokens to uppercase on each change)
//   ✓ Hint bar              (shows instruction semantics or error for cursor line)
//   ✓ Auto-scroll to PC     (smooth animation)
// ─────────────────────────────────────────────────────────────────────────────

class CodeEditorPanel extends StatefulWidget {
  const CodeEditorPanel({super.key});

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  // ── Constants ──────────────────────────────────────────────────────────────

  static const double _lineHeight = 21.75;
  static const double _topPadding = 14.0;
  static const double _overlayWidth = 310.0;
  static const double _hintBarHeight = 26.0;

  // ── Controller refs ────────────────────────────────────────────────────────

  final _cpu = Get.find<CpuController>();
  final _editor = Get.find<EditorController>();

  // ── Local state ────────────────────────────────────────────────────────────

  late final _AssemblyTextController _textCtrl;
  late final ScrollController _scrollCtrl;
  late final ScrollController _gutterScrollCtrl;
  late final FocusNode _focusNode;

  late final Worker _codeWorker;
  late final Worker _lineWorker;

  /// 0-based index of the line the cursor is currently on.
  /// Updated on every text change and cursor tap.
  int _cursorLine = 0;

  // ── Life-cycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _textCtrl = _AssemblyTextController(text: _cpu.code.value);
    _scrollCtrl = ScrollController();
    _gutterScrollCtrl = ScrollController();
    _scrollCtrl.addListener(_syncGutterScroll);

    _focusNode = FocusNode(onKeyEvent: _onKey);

    // Track cursor movement (e.g. mouse click repositions cursor).
    _textCtrl.addListener(_onCursorMoved);

    // Sync editor text when CpuController mutates code externally
    // (demo load, New button, Reset, …).
    _codeWorker = ever<String>(_cpu.code, (value) {
      if (_textCtrl.text == value) return;
      _textCtrl.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _editor.onCodeChanged(value);
      if (mounted) setState(() {});
      _scrollToLine(_cpu.currentLineIndex.value);
    });

    _lineWorker = ever<int?>(_cpu.currentLineIndex, _scrollToLine);

    // Initial live validation pass.
    _editor.onCodeChanged(_cpu.code.value);

    // Register the template-insertion callback so QuickPanel can reach the
    // TextEditingController without depending on it directly.
    _editor.onInsertTemplate = _insertTemplate;
  }

  @override
  void dispose() {
    _editor.onInsertTemplate = null;
    _codeWorker.dispose();
    _lineWorker.dispose();
    _scrollCtrl.removeListener(_syncGutterScroll);
    _textCtrl.removeListener(_onCursorMoved);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _gutterScrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Cursor tracking ────────────────────────────────────────────────────────

  void _onCursorMoved() {
    final offset = _textCtrl.selection.baseOffset;
    if (offset < 0) return;
    final text = _textCtrl.text;
    final clamped = offset.clamp(0, text.length);
    final line = text.substring(0, clamped).split('\n').length - 1;
    if (line != _cursorLine) {
      // Cursor moved to a new line — hide suggestions (avoid stale overlay).
      _editor.hideSuggestions();
      setState(() => _cursorLine = line);
    }
  }

  // ── Keyboard handling ──────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    final cmdCtrl = ctrl || meta;
    final key = event.logicalKey;

    // ── Ctrl/Cmd + Space — trigger autocomplete ────────────────────────────
    if (ctrl && key == LogicalKeyboardKey.space) {
      _triggerSuggestions();
      return KeyEventResult.handled;
    }

    // ── Ctrl/Cmd + Enter — load program ───────────────────────────────────
    if (cmdCtrl && key == LogicalKeyboardKey.enter) {
      _cpu.loadProgram();
      return KeyEventResult.handled;
    }

    // ── ESC — dismiss overlay ──────────────────────────────────────────────
    if (key == LogicalKeyboardKey.escape && _editor.showSuggestions.value) {
      _editor.hideSuggestions();
      return KeyEventResult.handled;
    }

    // ── Overlay navigation ─────────────────────────────────────────────────
    if (_editor.showSuggestions.value) {
      if (key == LogicalKeyboardKey.arrowUp) {
        _editor.moveSuggestion(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _editor.moveSuggestion(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
        _acceptSuggestion(_editor.selectedSuggestion);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ── Suggestion helpers ─────────────────────────────────────────────────────

  void _triggerSuggestions() {
    final code = _textCtrl.text;
    final offset = _textCtrl.selection.baseOffset;
    if (offset < 0 || offset > code.length) return;

    final lineStart = code.lastIndexOf('\n', offset - 1) + 1;
    final line = code.substring(lineStart, offset);
    final col = offset - lineStart;
    _editor.updateSuggestions(line, col);
  }

  void _acceptSuggestion(SuggestionItem? item) {
    if (item == null) return;

    final value = _textCtrl.value;
    final cursor = value.selection.baseOffset;
    if (cursor < 0) return;

    final text = value.text;

    // Walk backwards to find the start of the current partial token.
    var tokenStart = cursor;
    while (tokenStart > 0 &&
        text[tokenStart - 1] != ' ' &&
        text[tokenStart - 1] != '\n') {
      tokenStart--;
    }

    final newText =
        text.substring(0, tokenStart) + item.label + text.substring(cursor);
    final newCursor = tokenStart + item.label.length;

    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    _cpu.updateCode(newText);
    _editor.onCodeChanged(newText);
    _editor.hideSuggestions();
    setState(() {});
  }

  // ── Text change handler ────────────────────────────────────────────────────

  void _onChanged(String raw) {
    // Auto-format: uppercase known tokens. Character count never changes, so
    // the cursor selection remains valid after the substitution.
    final formatted = _editor.autoFormat(raw);
    if (formatted != raw) {
      final sel = _textCtrl.selection;
      _textCtrl.value = TextEditingValue(text: formatted, selection: sel);
      _cpu.updateCode(formatted);
      _editor.onCodeChanged(formatted);
      _refreshSuggestions(formatted);
    } else {
      _cpu.updateCode(raw);
      _editor.onCodeChanged(raw);
      _refreshSuggestions(raw);
    }
    // Update _cursorLine inline (avoids a separate setState call).
    final offset = _textCtrl.selection.baseOffset;
    if (offset >= 0 && offset <= _textCtrl.text.length) {
      _cursorLine = _textCtrl.text.substring(0, offset).split('\n').length - 1;
    }
    setState(() {});
  }

  // ── Template insertion (called by QuickPanel via EditorController) ─────────

  static const _inserter = TemplateInserter();

  void _insertTemplate(InstructionModel model) {
    final newValue = _inserter.insert(current: _textCtrl.value, model: model);

    _textCtrl.value = newValue;
    _cpu.updateCode(newValue.text);
    _editor.onCodeChanged(newValue.text);
    _editor.hideSuggestions();

    // Keep _cursorLine in sync with the new selection.
    final offset = newValue.selection.baseOffset;
    if (offset >= 0 && offset <= newValue.text.length) {
      _cursorLine = newValue.text.substring(0, offset).split('\n').length - 1;
    }

    setState(() {});
    // Return focus to the editor so the user can start typing immediately.
    _focusNode.requestFocus();
  }

  /// Recomputes suggestions from the current cursor position in [code].
  void _refreshSuggestions(String code) {
    final offset = _textCtrl.selection.baseOffset;
    if (offset < 0 || offset > code.length) return;
    final lineStart = code.lastIndexOf('\n', offset - 1) + 1;
    final line = code.substring(lineStart, math.min(offset, code.length));
    final col = offset - lineStart;
    _editor.updateSuggestions(line, col);
  }

  // ── Scroll helpers ─────────────────────────────────────────────────────────

  void _syncGutterScroll() {
    if (!_gutterScrollCtrl.hasClients) return;
    final max = _gutterScrollCtrl.position.maxScrollExtent;
    final target = _scrollCtrl.offset.clamp(0.0, max);
    if ((_gutterScrollCtrl.offset - target).abs() > 0.5) {
      _gutterScrollCtrl.jumpTo(target);
    }
  }

  void _scrollToLine(int? lineIndex) {
    if (lineIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final target = math.max(0, (lineIndex - 2) * _lineHeight);
      final maxExt = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.animateTo(
        math.min(target.toDouble(), maxExt),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Hint bar ───────────────────────────────────────────────────────────────

  /// Returns the text and error flag for the hint bar at the cursor line.
  ({String text, bool isError}) _hintContent() {
    final errors = _editor.lineErrors;
    final hints = _editor.lineHints;
    if (errors.containsKey(_cursorLine)) {
      return (text: errors[_cursorLine]!, isError: true);
    }
    if (hints.containsKey(_cursorLine)) {
      return (text: hints[_cursorLine]!, isError: false);
    }
    return (text: '', isError: false);
  }

  // ── Convenience ───────────────────────────────────────────────────────────

  int get _lineCount => math.max(1, _textCtrl.text.split('\n').length);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Assembly Program',
      actions: [_ShortcutHint()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildEditorArea()),
          // Hint bar reacts to live errors/hints (Obx) and _cursorLine (setState).
          Obx(_buildHintBar),
        ],
      ),
    );
  }

  // ── Editor area (gutter + stack: highlights, text field, overlay) ──────────

  Widget _buildEditorArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gutter — reacts to CPU line index, CPU error, and live line errors.
        Obx(
          () => LineNumberGutter(
            lineCount: _lineCount,
            activeLineIndex: _cpu.currentLineIndex.value,
            errorLineIndex: _cpu.errorLineIndex.value,
            lineErrors: Map<int, String>.from(_editor.lineErrors),
            scrollController: _gutterScrollCtrl,
            lineHeight: _lineHeight,
            topPadding: _topPadding,
          ),
        ),

        // Editor content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                // ── Background line-highlight stripes ──────────────────────
                Obx(
                  () => _LineHighlights(
                    activeLineIndex: _cpu.currentLineIndex.value,
                    errorLineIndex: _cpu.errorLineIndex.value,
                    scrollController: _scrollCtrl,
                    lineHeight: _lineHeight,
                    topPadding: _topPadding,
                    viewportHeight: constraints.maxHeight,
                  ),
                ),

                // ── Main text field ────────────────────────────────────────
                TextField(
                  controller: _textCtrl,
                  scrollController: _scrollCtrl,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(_topPadding),
                  ),
                ),

                // ── Autocomplete overlay ───────────────────────────────────
                // Obx reacts to showSuggestions / suggestions / selectedIndex.
                // _cursorLine is captured from the outer closure, kept current
                // by setState calls in _onChanged / _onCursorMoved.
                Obx(() => _buildOverlay(constraints)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Autocomplete overlay ───────────────────────────────────────────────────

  Widget _buildOverlay(BoxConstraints constraints) {
    if (!_editor.showSuggestions.value || _editor.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reposition whenever the user scrolls.
    return AnimatedBuilder(
      animation: _scrollCtrl,
      builder: (_, _) {
        final scrollOff = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;

        // Place overlay just below the cursor line's bottom edge.
        final top = _topPadding + (_cursorLine + 1) * _lineHeight - scrollOff;

        // Don't draw if off-screen.
        if (top < 0 || top > constraints.maxHeight - 20) {
          return const SizedBox.shrink();
        }

        final width = math.min(_overlayWidth, constraints.maxWidth - 16);
        return Positioned(
          top: top,
          left: 8.0,
          width: width,
          child: SuggestionOverlay(
            items: _editor.suggestions,
            selectedIndex: _editor.selectedIndex.value,
            onSelect: _acceptSuggestion,
            onDismiss: _editor.hideSuggestions,
          ),
        );
      },
    );
  }

  // ── Hint bar ───────────────────────────────────────────────────────────────

  Widget _buildHintBar() {
    final hint = _hintContent();

    // Empty line → keep a thin spacer so the panel height stays stable.
    if (hint.text.isEmpty) {
      return const SizedBox(height: _hintBarHeight);
    }

    return Container(
      height: _hintBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: hint.isError
            ? AppColors.danger.withValues(alpha: 0.07)
            : AppColors.surfaceAlt.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(
            color: hint.isError
                ? AppColors.danger.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hint.isError ? Icons.error_outline : Icons.arrow_right_alt,
            size: 12,
            color: hint.isError ? AppColors.danger : AppColors.dimText,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hint.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hint.isError ? AppColors.danger : AppColors.dimText,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AssemblyTextController
// Delegates buildTextSpan to AssemblySyntaxHighlighter.
// ─────────────────────────────────────────────────────────────────────────────

class _AssemblyTextController extends TextEditingController {
  _AssemblyTextController({required super.text});

  static const _hl = AssemblySyntaxHighlighter();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => _hl.build(text, style ?? const TextStyle());
}

// ─────────────────────────────────────────────────────────────────────────────
// _LineHighlights — background stripes for PC and error lines.
// (Identical behaviour to the original; kept private here.)
// ─────────────────────────────────────────────────────────────────────────────

class _LineHighlights extends StatelessWidget {
  const _LineHighlights({
    required this.activeLineIndex,
    required this.errorLineIndex,
    required this.scrollController,
    required this.lineHeight,
    required this.topPadding,
    required this.viewportHeight,
  });

  final int? activeLineIndex;
  final int? errorLineIndex;
  final ScrollController scrollController;
  final double lineHeight;
  final double topPadding;
  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    if (activeLineIndex == null && errorLineIndex == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: scrollController,
      builder: (_, _) {
        final off = scrollController.hasClients ? scrollController.offset : 0.0;
        return Stack(
          children: [
            if (activeLineIndex != null)
              _Stripe(
                lineIndex: activeLineIndex!,
                scrollOffset: off,
                topPadding: topPadding,
                lineHeight: lineHeight,
                viewportHeight: viewportHeight,
                color: AppColors.accent,
              ),
            if (errorLineIndex != null)
              _Stripe(
                lineIndex: errorLineIndex!,
                scrollOffset: off,
                topPadding: topPadding,
                lineHeight: lineHeight,
                viewportHeight: viewportHeight,
                color: AppColors.danger,
              ),
          ],
        );
      },
    );
  }
}

class _Stripe extends StatelessWidget {
  const _Stripe({
    required this.lineIndex,
    required this.scrollOffset,
    required this.topPadding,
    required this.lineHeight,
    required this.viewportHeight,
    required this.color,
  });

  final int lineIndex;
  final double scrollOffset;
  final double topPadding;
  final double lineHeight;
  final double viewportHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final top = topPadding + lineIndex * lineHeight - scrollOffset;
    if (top < -lineHeight || top > viewportHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: lineHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShortcutHint — small badge in the panel header reminding users of shortcuts.
// ─────────────────────────────────────────────────────────────────────────────

class _ShortcutHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _badge('⌃Space', 'autocomplete'),
          const SizedBox(width: 6),
          _badge('⌃↵', 'load'),
        ],
      ),
    );
  }

  Widget _badge(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.dimText, fontSize: 9),
        ),
      ],
    );
  }
}
