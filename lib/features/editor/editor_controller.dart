import 'dart:async';

import 'package:get/get.dart';

import '../quick_panel/instruction_model.dart';
import 'editor_state.dart';
import 'suggestion_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditorController — GetX controller for editor UI state only.
//
// Responsibilities:
//   • Live validation — parses each line while the user types (debounced) and
//     exposes per-line error messages + instruction hints.
//   • Autocomplete — wraps SuggestionEngine and exposes reactive suggestion
//     state (visible, items, selected index).
//   • Auto-format — normalises known tokens to uppercase without changing
//     character count (so cursor offsets stay valid after formatting).
//
// Deliberately has NO knowledge of CpuController or CPU execution state.
// ─────────────────────────────────────────────────────────────────────────────

class EditorController extends GetxController {
  static const _debounceMs = 300;
  static const _knownInstructions = {
    'MOV',
    'XCHG',
    'ADD',
    'SUB',
    'INC',
    'DEC',
    'MUL',
    'DIV',
    'AND',
    'OR',
    'XOR',
    'ROL',
    'ROR',
    'RET',
  };
  static const _knownRegisters = {
    'AX',
    'BX',
    'CX',
    'DX',
    'AH',
    'AL',
    'BH',
    'BL',
    'CH',
    'CL',
    'DH',
    'DL',
  };
  static const _knownTokens = {..._knownInstructions, ..._knownRegisters};

  // Operand signatures for validation: 'R' = register, 'I' = integer.
  static const _sigs = <String, List<String>>{
    'MOV': ['R', 'V'],
    'XCHG': ['R', 'R'],
    'ADD': ['R', 'V'],
    'SUB': ['R', 'V'],
    'INC': ['R'],
    'DEC': ['R'],
    'MUL': ['V'],
    'DIV': ['V'],
    'AND': ['R', 'V'],
    'OR': ['R', 'V'],
    'XOR': ['R', 'V'],
    'ROL': ['R', 'I'],
    'ROR': ['R', 'I'],
    'RET': [],
  };

  static const _examples = <String, String>{
    'MOV': 'MOV AX,12CDH',
    'XCHG': 'XCHG AX,BX',
    'ADD': 'ADD AX,BX',
    'SUB': 'SUB AX,2H',
    'INC': 'INC AX',
    'DEC': 'DEC AX',
    'MUL': 'MUL BL',
    'DIV': 'DIV BL',
    'AND': 'AND AL,BL',
    'OR': 'OR AL,01H',
    'XOR': 'XOR AL,05H',
    'ROL': 'ROL AL,1',
    'ROR': 'ROR AL,1',
    'RET': 'RET',
  };

  final _engine = const SuggestionEngine();
  Timer? _debounce;

  // ── Template insertion gateway ─────────────────────────────────────────────
  //
  // [CodeEditorPanel] registers this callback in initState and clears it in
  // dispose.  [QuickPanel] calls it via [requestInsert] without ever touching
  // the TextEditingController directly.
  void Function(InstructionModel)? onInsertTemplate;

  // ── Observable state ───────────────────────────────────────────────────────

  /// lineIndex (0-based) → human-readable error string.
  final lineErrors = <int, String>{}.obs;

  /// lineIndex (0-based) → short semantic hint for valid lines.
  final lineHints = <int, String>{}.obs;

  /// Current autocomplete items.
  final suggestions = <SuggestionItem>[].obs;

  final showSuggestions = false.obs;
  final selectedIndex = 0.obs;

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Call on every code change. Runs validation after a short debounce.
  void onCodeChanged(String code) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: _debounceMs),
      () => _validate(code),
    );
  }

  void _validate(String code) {
    final errors = <int, String>{};
    final hints = <int, String>{};
    final lines = code.split(RegExp(r'\r?\n'));

    for (var i = 0; i < lines.length; i++) {
      final raw = _stripComment(lines[i]).trim();
      if (raw.isEmpty) continue;

      final (err, hint) = _checkLine(raw);
      if (err != null) errors[i] = err;
      if (hint != null) hints[i] = hint;
    }

    lineErrors.assignAll(errors);
    lineHints.assignAll(hints);
  }

  /// Returns (errorMessage?, hintText?) for a single non-empty, comment-free line.
  (String?, String?) _checkLine(String line) {
    final parts = line
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (null, null);

    final mnemonic = parts.first.toUpperCase();

    if (!_knownInstructions.contains(mnemonic)) {
      return ('"$mnemonic" is not a recognised instruction', null);
    }

    final sig = _sigs[mnemonic]!;
    final operands = parts.skip(1).map((p) => p.toUpperCase()).toList();
    final example = _examples[mnemonic]!;

    if (operands.length != sig.length) {
      final n = sig.length;
      return (
        '$mnemonic needs $n operand${n == 1 ? '' : 's'} '
            '(e.g. $example)',
        null,
      );
    }

    for (var oi = 0; oi < sig.length; oi++) {
      final raw = parts[oi + 1];
      final upper = raw.toUpperCase();
      if (sig[oi] == 'R' && !_knownRegisters.contains(upper)) {
        return (
          '$mnemonic: operand ${oi + 1} must be an 8086 register, '
              'got "$raw"',
          null,
        );
      }
      if (sig[oi] == 'V' &&
          !_knownRegisters.contains(upper) &&
          !_isImmediate(raw)) {
        return (
          '$mnemonic: operand ${oi + 1} must be a register or hex value, '
              'got "$raw"',
          null,
        );
      }
      if (sig[oi] == 'I' && !_isImmediate(raw)) {
        return (
          '$mnemonic: operand ${oi + 1} must be a decimal or hex value, got "$raw"',
          null,
        );
      }
    }

    return (null, _hintFor(mnemonic, operands));
  }

  String _hintFor(String mnemonic, List<String> ops) {
    switch (mnemonic) {
      case 'MOV':
        return '${ops[0]} ← ${ops[1]}';
      case 'XCHG':
        return '${ops[0]} ↔ ${ops[1]}';
      case 'ADD':
        return '${ops[0]} ← ${ops[0]} + ${ops[1]}';
      case 'SUB':
        return '${ops[0]} ← ${ops[0]} − ${ops[1]}';
      case 'INC':
        return '${ops[0]} ← ${ops[0]} + 1';
      case 'DEC':
        return '${ops[0]} ← ${ops[0]} − 1';
      case 'MUL':
        return 'AX ← AL × ${ops[0]}';
      case 'DIV':
        return 'AL ← AX / ${ops[0]}, AH ← remainder';
      case 'AND':
        return '${ops[0]} ← ${ops[0]} AND ${ops[1]}';
      case 'OR':
        return '${ops[0]} ← ${ops[0]} OR  ${ops[1]}';
      case 'XOR':
        return '${ops[0]} ← ${ops[0]} XOR ${ops[1]}';
      case 'ROL':
        return '${ops[0]} rotate left by ${ops[1]}';
      case 'ROR':
        return '${ops[0]} rotate right by ${ops[1]}';
      case 'RET':
        return 'Return / stop execution';
      default:
        return '';
    }
  }

  // ── Autocomplete ───────────────────────────────────────────────────────────

  /// Updates the suggestion list for [line] at cursor column [col].
  void updateSuggestions(String line, int col) {
    final items = _engine.suggest(line, col);
    suggestions.assignAll(items);
    showSuggestions.value = items.isNotEmpty;
    if (items.isNotEmpty) selectedIndex.value = 0;
  }

  void hideSuggestions() => showSuggestions.value = false;

  /// Move selection up (delta = -1) or down (delta = +1).
  void moveSuggestion(int delta) {
    if (suggestions.isEmpty) return;
    selectedIndex.value = (selectedIndex.value + delta).clamp(
      0,
      suggestions.length - 1,
    );
  }

  /// Currently highlighted suggestion, or null if the overlay is hidden.
  SuggestionItem? get selectedSuggestion {
    if (!showSuggestions.value || suggestions.isEmpty) return null;
    final idx = selectedIndex.value.clamp(0, suggestions.length - 1);
    return suggestions[idx];
  }

  // ── Auto-format ────────────────────────────────────────────────────────────

  /// Returns [code] with known tokens uppercased.
  ///
  /// Because only the case of characters changes — never the character count —
  /// the caller's cursor offset remains valid after substitution.
  String autoFormat(String code) {
    final lines = code.split('\n');
    return lines.map(_formatLine).join('\n');
  }

  String _formatLine(String line) {
    final commentAt = _commentAt(line);
    final code = commentAt >= 0 ? line.substring(0, commentAt) : line;
    final comment = commentAt >= 0 ? line.substring(commentAt) : '';

    final formatted = code.replaceAllMapped(RegExp(r'\S+'), (m) {
      final token = m.group(0)!;
      final upper = token.replaceAll(',', '').toUpperCase();
      return _knownTokens.contains(upper) ? upper : token;
    });

    return formatted + comment;
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  int _commentAt(String line) {
    final s = line.indexOf(';');
    final h = line.indexOf('#');
    if (s < 0 && h < 0) return -1;
    if (s < 0) return h;
    if (h < 0) return s;
    return s < h ? s : h;
  }

  String _stripComment(String line) {
    final at = _commentAt(line);
    return at >= 0 ? line.substring(0, at) : line;
  }

  bool _isImmediate(String value) {
    final token = value.toUpperCase();
    if (token.endsWith('H')) {
      final hex = token.substring(0, token.length - 1);
      return hex.isNotEmpty && RegExp(r'^[0-9A-F]+$').hasMatch(hex);
    }
    return int.tryParse(token) != null;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
