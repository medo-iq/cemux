import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';

class InstructionReferenceDialog extends StatelessWidget {
  const InstructionReferenceDialog({super.key});

  static const List<_InstructionReferenceItem> _items = [
    _InstructionReferenceItem(
      instruction: 'MOV',
      syntax: 'MOV dst,src',
      description: 'Move a register or immediate value into a register.',
      example: 'MOV AX,12CDH',
    ),
    _InstructionReferenceItem(
      instruction: 'XCHG',
      syntax: 'XCHG reg,reg',
      description: 'Exchange two register values.',
      example: 'XCHG AX,BX',
    ),
    _InstructionReferenceItem(
      instruction: 'ADD',
      syntax: 'ADD dst,src',
      description: 'Add source register or immediate into destination.',
      example: 'ADD AX,BX',
    ),
    _InstructionReferenceItem(
      instruction: 'SUB',
      syntax: 'SUB dst,src',
      description: 'Subtract source register or immediate from destination.',
      example: 'SUB AX,2H',
    ),
    _InstructionReferenceItem(
      instruction: 'INC',
      syntax: 'INC reg',
      description: 'Increment a register by one.',
      example: 'INC AX',
    ),
    _InstructionReferenceItem(
      instruction: 'DEC',
      syntax: 'DEC reg',
      description: 'Decrement a register by one.',
      example: 'DEC AX',
    ),
    _InstructionReferenceItem(
      instruction: 'MUL',
      syntax: 'MUL src',
      description: 'Simplified unsigned multiply: AX = AL * source.',
      example: 'MUL BL',
    ),
    _InstructionReferenceItem(
      instruction: 'DIV',
      syntax: 'DIV src',
      description:
          'Simplified divide: AL receives quotient, AH receives remainder.',
      example: 'DIV BL',
    ),
    _InstructionReferenceItem(
      instruction: 'AND',
      syntax: 'AND dst,src',
      description: 'Apply bitwise AND.',
      example: 'AND AL,BL',
    ),
    _InstructionReferenceItem(
      instruction: 'OR',
      syntax: 'OR dst,src',
      description: 'Apply bitwise OR.',
      example: 'OR AL,01H',
    ),
    _InstructionReferenceItem(
      instruction: 'XOR',
      syntax: 'XOR dst,src',
      description: 'Apply bitwise XOR.',
      example: 'XOR AL,05H',
    ),
    _InstructionReferenceItem(
      instruction: 'ROL',
      syntax: 'ROL reg,1',
      description: 'Rotate a register left by one bit.',
      example: 'ROL AL,1',
    ),
    _InstructionReferenceItem(
      instruction: 'ROR',
      syntax: 'ROR reg,1',
      description: 'Rotate a register right by one bit.',
      example: 'ROR AL,1',
    ),
    _InstructionReferenceItem(
      instruction: 'RET',
      syntax: 'RET',
      description: 'Stop execution and return from the program.',
      example: 'RET',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instruction Reference',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Simplified 8086 instruction set only',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _InstructionReferenceRow(item: _items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionReferenceRow extends StatelessWidget {
  const _InstructionReferenceRow({required this.item});

  final _InstructionReferenceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final instructionCell = _InstructionCell(
            width: compact ? null : 94,
            label: 'Instruction',
            value: item.instruction,
            emphasized: true,
          );
          final syntaxCell = _InstructionCell(
            width: compact ? null : 130,
            label: 'Syntax',
            value: item.syntax,
          );
          final exampleCell = _InstructionCell(
            width: compact ? null : 130,
            label: 'Example',
            value: item.example,
          );
          final meaningCell = _InstructionCell(
            label: 'Meaning',
            value: item.description,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                instructionCell,
                const SizedBox(height: 8),
                syntaxCell,
                const SizedBox(height: 8),
                exampleCell,
                const SizedBox(height: 8),
                meaningCell,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              instructionCell,
              syntaxCell,
              exampleCell,
              Expanded(child: meaningCell),
            ],
          );
        },
      ),
    );
  }
}

class _InstructionCell extends StatelessWidget {
  const _InstructionCell({
    required this.label,
    required this.value,
    this.width,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final double? width;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: emphasized ? AppColors.accent : AppColors.text,
            fontFamily: emphasized ? null : 'monospace',
            fontSize: 13,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );

    if (width == null) {
      return content;
    }

    return SizedBox(width: width, child: content);
  }
}

class _InstructionReferenceItem {
  const _InstructionReferenceItem({
    required this.instruction,
    required this.syntax,
    required this.description,
    required this.example,
  });

  final String instruction;
  final String syntax;
  final String description;
  final String example;
}
