import 'editor_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionEngine — pure, stateless, const-constructible.
//
// Given a single assembly line and the cursor column, returns a ranked list of
// context-aware suggestions.
//
// Context rules:
//   Column 0 (no space yet)     → suggest matching instruction mnemonics
//   After mnemonic + space      → suggest first operand (register)
//   After first operand comma   → suggest second operand when it is register-like
//   Past all operands           → no suggestions
//
// Immediate values use 8086 hex syntax, for example 12CDH or 0FH.
// ─────────────────────────────────────────────────────────────────────────────

class SuggestionEngine {
  const SuggestionEngine();

  static const _instructions = [
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
  ];

  static const _registers = [
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
  ];

  /// Operand signature per instruction. 'R' = register, 'I' = immediate.
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

  static const _details = <String, String>{
    'MOV': 'MOV AX,12CDH — move register or immediate value',
    'XCHG': 'XCHG AX,BX — exchange two registers',
    'ADD': 'ADD AX,BX — add source into destination',
    'SUB': 'SUB AX,2H — subtract source from destination',
    'INC': 'INC AX — increment register',
    'DEC': 'DEC AX — decrement register',
    'MUL': 'MUL BL — AX = AL * BL',
    'DIV': 'DIV BL — AL = AX / BL, AH = remainder',
    'AND': 'AND AL,BL — bitwise AND',
    'OR': 'OR AL,01H — bitwise OR',
    'XOR': 'XOR AL,05H — bitwise XOR',
    'ROL': 'ROL AL,1 — rotate left by one bit',
    'ROR': 'ROR AL,1 — rotate right by one bit',
    'RET': 'RET — stop execution',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns suggestions for [line] with the cursor at character [col].
  ///
  /// [line] must be a single assembly line (no newlines).
  /// [col]  is the cursor offset from the start of [line].
  List<SuggestionItem> suggest(String line, int col) {
    // Strip inline comment — don't suggest inside comment text.
    final clean = _stripComment(line);
    final textBeforeCursor = col <= clean.length
        ? clean.substring(0, col)
        : clean;

    final leading = textBeforeCursor.trimLeft();
    final tokens = leading.replaceAll(',', ' ').split(RegExp(r'\s+'));
    final nonEmpty = tokens.where((t) => t.isNotEmpty).toList();
    final endsWithSpace = textBeforeCursor.endsWith(' ');

    // ── Nothing typed yet ─────────────────────────────────────────────────
    if (nonEmpty.isEmpty) {
      return _instrSuggestions('');
    }

    // ── Still completing the instruction mnemonic ─────────────────────────
    if (nonEmpty.length == 1 && !endsWithSpace) {
      return _instrSuggestions(nonEmpty.first.toUpperCase());
    }

    // ── Past the mnemonic — figure out which operand slot we're in ─────────
    final mnemonic = nonEmpty.first.toUpperCase();
    final sig = _sigs[mnemonic];
    if (sig == null) return []; // unknown instruction

    // operandIndex = 0-based index into the signature list.
    final operandIndex = endsWithSpace
        ? nonEmpty.length - 1
        : nonEmpty.length - 2;

    if (operandIndex < 0 || operandIndex >= sig.length) return [];

    final partial = endsWithSpace ? '' : nonEmpty.last.toUpperCase();

    if (sig[operandIndex] == 'R' || sig[operandIndex] == 'V') {
      return _regSuggestions(partial);
    }
    return []; // 'I' slot — let the user type the number freely
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<SuggestionItem> _instrSuggestions(String prefix) {
    return _instructions
        .where((i) => i.startsWith(prefix))
        .map(
          (i) => SuggestionItem(
            label: i,
            kind: SuggestionKind.instruction,
            detail: _details[i] ?? '',
          ),
        )
        .toList();
  }

  List<SuggestionItem> _regSuggestions(String prefix) {
    return _registers
        .where((r) => r.startsWith(prefix))
        .map(
          (r) => SuggestionItem(
            label: r,
            kind: SuggestionKind.register,
            detail: 'General-purpose register',
          ),
        )
        .toList();
  }

  String _stripComment(String line) {
    final s = line.indexOf(';');
    final h = line.indexOf('#');
    if (s < 0 && h < 0) return line;
    if (s < 0) return line.substring(0, h);
    if (h < 0) return line.substring(0, s);
    return line.substring(0, s < h ? s : h);
  }
}
