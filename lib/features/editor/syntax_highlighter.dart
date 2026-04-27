import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AssemblySyntaxHighlighter — pure, stateless, const-constructible.
//
// Converts assembly source text into a styled TextSpan tree suitable for use
// inside a TextEditingController.buildTextSpan override.
//
// Design decisions:
//  • Processes text line-by-line so inline comments are handled correctly —
//    tokens that appear after ; or # are rendered as comment style, not as
//    instructions or registers.
//  • Uses a single regex pass per line for efficiency.
//  • Unknown non-whitespace tokens are rendered in a dimmed danger colour to
//    give the user a visual "this doesn't look right" cue without being harsh.
// ─────────────────────────────────────────────────────────────────────────────

class AssemblySyntaxHighlighter {
  const AssemblySyntaxHighlighter();

  static const _instructions = {
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
  static const _registers = {
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

  // Matches one run of whitespace OR one run of non-whitespace.
  static final _tokenRe = RegExp(r'\s+|[^\s]+');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a [TextSpan] tree for [text] rooted at [base] style.
  TextSpan build(String text, TextStyle base) {
    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      spans.addAll(_lineSpans(lines[i], base));
      if (i < lines.length - 1) {
        // Preserve newline characters so the TextField renders correctly.
        spans.add(TextSpan(text: '\n', style: base));
      }
    }

    return TextSpan(style: base, children: spans);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<InlineSpan> _lineSpans(String line, TextStyle base) {
    final commentAt = _commentStart(line);
    final codePart = commentAt >= 0 ? line.substring(0, commentAt) : line;
    final commentPart = commentAt >= 0 ? line.substring(commentAt) : null;

    final spans = <InlineSpan>[];

    for (final m in _tokenRe.allMatches(codePart)) {
      final token = m.group(0)!;
      spans.add(TextSpan(text: token, style: _styleFor(base, token)));
    }

    if (commentPart != null) {
      spans.add(
        TextSpan(
          text: commentPart,
          style: base.copyWith(
            color: AppColors.mutedText,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return spans;
  }

  /// Returns the index of the first ; or # that starts a comment, or -1.
  int _commentStart(String line) {
    final s = line.indexOf(';');
    final h = line.indexOf('#');
    if (s < 0 && h < 0) return -1;
    if (s < 0) return h;
    if (h < 0) return s;
    return s < h ? s : h;
  }

  TextStyle _styleFor(TextStyle base, String token) {
    // Whitespace — keep base style (no visible change).
    if (token.trim().isEmpty) return base;

    final upper = token.replaceAll(',', '').toUpperCase();

    if (_instructions.contains(upper)) {
      return base.copyWith(
        color: AppColors.accent,
        fontWeight: FontWeight.w700,
      );
    }

    if (_registers.contains(upper)) {
      return base.copyWith(
        color: AppColors.codeBlue,
        fontWeight: FontWeight.w600,
      );
    }

    if (_isImmediate(upper)) {
      return base.copyWith(color: AppColors.changed);
    }

    // Unrecognised token — dim danger tint as a subtle error hint.
    return base.copyWith(color: AppColors.danger.withValues(alpha: 0.70));
  }

  bool _isImmediate(String token) {
    if (token.endsWith('H')) {
      final hex = token.substring(0, token.length - 1);
      return hex.isNotEmpty && RegExp(r'^[0-9A-F]+$').hasMatch(hex);
    }
    return int.tryParse(token) != null;
  }
}
