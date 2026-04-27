// ─────────────────────────────────────────────────────────────────────────────
// InstructionModel — pure data, no Flutter or GetX dependencies.
//
// Each entry describes:
//   • The mnemonic label shown on the button.
//   • A one-liner subtitle that hints at the operand shape.
//   • The exact template string that will be inserted.
//   • [selectionStart] / [selectionEnd] — byte offsets *within the template*
//     that define what gets selected after insertion.
//     These let the user immediately start typing to replace the most
//     interesting placeholder (destination register or immediate value).
//
// Templates use simplified 8086 syntax, for example MOV AX,12CDH.
// ─────────────────────────────────────────────────────────────────────────────

class InstructionModel {
  const InstructionModel({
    required this.name,
    required this.subtitle,
    required this.template,
    required this.selectionStart,
    required this.selectionEnd,
  });

  /// Button label — the instruction mnemonic.
  final String name;

  /// Small hint line below the label, e.g. "R←N".
  final String subtitle;

  /// The text that gets inserted into the editor.
  final String template;

  /// Byte offset (0-based, within [template]) where the post-insertion
  /// selection starts.
  final int selectionStart;

  /// Byte offset (exclusive) where the post-insertion selection ends.
  final int selectionEnd;

  // ── Canonical set of supported 8086 educational instructions ───────────────

  static const all = <InstructionModel>[
    InstructionModel(
      name: 'MOV',
      subtitle: 'R ← V',
      template: 'MOV AX,12CDH',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'XCHG',
      subtitle: 'Ra ↔ Rb',
      template: 'XCHG AX,BX',
      selectionStart: 5,
      selectionEnd: 7,
    ),
    InstructionModel(
      name: 'ADD',
      subtitle: 'R + V',
      template: 'ADD AX,BX',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'SUB',
      subtitle: 'R − V',
      template: 'SUB AX,2H',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'INC',
      subtitle: 'R + 1',
      template: 'INC AX',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'DEC',
      subtitle: 'R − 1',
      template: 'DEC AX',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'MUL',
      subtitle: 'AX←AL×R',
      template: 'MUL BL',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'DIV',
      subtitle: 'AX/R',
      template: 'DIV BL',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'AND',
      subtitle: 'R & V',
      template: 'AND AL,BL',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'OR',
      subtitle: 'R | V',
      template: 'OR AL,01H',
      selectionStart: 3,
      selectionEnd: 5,
    ),
    InstructionModel(
      name: 'XOR',
      subtitle: 'R ^ V',
      template: 'XOR AL,05H',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'ROL',
      subtitle: 'R ← rot',
      template: 'ROL AL,1',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'ROR',
      subtitle: 'R → rot',
      template: 'ROR AL,1',
      selectionStart: 4,
      selectionEnd: 6,
    ),
    InstructionModel(
      name: 'RET',
      subtitle: 'return',
      template: 'RET',
      selectionStart: 0,
      selectionEnd: 3,
    ),
  ];
}
