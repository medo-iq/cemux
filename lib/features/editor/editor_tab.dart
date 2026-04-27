import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/controllers/cpu_controller.dart';
import '../../colors/app_colors.dart';
import '../../core/cpu/hex_utils.dart';
import '../../core/models/cpu_phase.dart';
import 'code_editor_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditorTab
// Layout: code editor (flex 7) | info sidebar (fixed 272 px)
// ─────────────────────────────────────────────────────────────────────────────

class EditorTab extends StatelessWidget {
  const EditorTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left — assembly editor
        Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 0, 16),
            child: CodeEditorPanel(),
          ),
        ),
        // Right — info sidebar
        _InfoSidebar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right sidebar shell
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSidebar extends StatelessWidget {
  const _InfoSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CpuStatusSection(),
          Divider(height: 1, color: AppColors.border),
          _PipelineSection(),
          Divider(height: 1, color: AppColors.border),
          Expanded(child: _RegistersMiniSection()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — CPU status (phase + instruction)
// ─────────────────────────────────────────────────────────────────────────────

class _CpuStatusSection extends StatelessWidget {
  const _CpuStatusSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Obx(() {
      final phase = c.phase.value;
      final instruction = c.currentInstruction.value;
      final hasError = c.errorMessage.value.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: phase pill + running indicator
            Row(
              children: [
                _PhasePill(phase: phase),
                const Spacer(),
                if (c.status.value.isRunning)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Running',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            if (hasError)
              Text(
                c.errorMessage.value,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              )
            else if (instruction.isNotEmpty) ...[
              _InstructionChips(instruction: instruction),
              const SizedBox(height: 7),
              Text(
                _explain(instruction, phase, c),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              Text(
                c.statusMessage.value,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    });
  }

  String _explain(String instr, CpuPhase phase, CpuController c) {
    switch (phase) {
      case CpuPhase.fetch:
        final addr = c.pc.value > 0 ? c.pc.value - 1 : 0;
        return 'Reading instruction at address $addr';
      case CpuPhase.decode:
        return 'Validating syntax and resolving operands';
      case CpuPhase.execute:
        return _executeExpl(instr);
      case CpuPhase.halted:
        return 'Program finished execution';
      case CpuPhase.idle:
        return c.statusMessage.value;
    }
  }

  String _executeExpl(String instr) {
    final p = instr.replaceAll(',', ' ').split(RegExp(r'\s+'));
    if (p.isEmpty) return '';
    switch (p[0]) {
      case 'MOV':
        return p.length >= 3 ? '${p[1]} ← ${p[2]}' : '';
      case 'XCHG':
        return p.length >= 3 ? '${p[1]} ↔ ${p[2]}' : '';
      case 'ADD':
        return p.length >= 3 ? '${p[1]} ← ${p[1]} + ${p[2]}' : '';
      case 'SUB':
        return p.length >= 3 ? '${p[1]} ← ${p[1]} − ${p[2]}' : '';
      case 'INC':
        return p.length >= 2 ? '${p[1]} ← ${p[1]} + 1' : '';
      case 'DEC':
        return p.length >= 2 ? '${p[1]} ← ${p[1]} − 1' : '';
      case 'MUL':
        return p.length >= 2 ? 'AX ← AL × ${p[1]}' : '';
      case 'DIV':
        return p.length >= 2 ? 'AL ← AX / ${p[1]}, AH ← remainder' : '';
      case 'AND':
        return p.length >= 3 ? '${p[1]} ← ${p[1]} AND ${p[2]}' : '';
      case 'OR':
        return p.length >= 3 ? '${p[1]} ← ${p[1]} OR ${p[2]}' : '';
      case 'XOR':
        return p.length >= 3 ? '${p[1]} ← ${p[1]} XOR ${p[2]}' : '';
      case 'ROL':
        return p.length >= 3 ? '${p[1]} rotate left by ${p[2]}' : '';
      case 'ROR':
        return p.length >= 3 ? '${p[1]} rotate right by ${p[2]}' : '';
      case 'RET':
        return 'Return / stop execution';
      default:
        return '';
    }
  }
}

// ─── Phase pill ───────────────────────────────────────────────────────────────

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.phase});

  final CpuPhase phase;

  @override
  Widget build(BuildContext context) {
    final color = _color(phase);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        phase.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _color(CpuPhase p) {
    switch (p) {
      case CpuPhase.fetch:
        return AppColors.accentBlue;
      case CpuPhase.decode:
        return AppColors.accent;
      case CpuPhase.execute:
        return AppColors.changed;
      case CpuPhase.halted:
        return AppColors.success;
      case CpuPhase.idle:
        return AppColors.dimText;
    }
  }
}

// ─── Instruction token chips ──────────────────────────────────────────────────

class _InstructionChips extends StatelessWidget {
  const _InstructionChips({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    final parts = instruction.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < parts.length; i++)
          _Chip(label: parts[i], isOpcode: i == 0),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isOpcode});

  final String label;
  final bool isOpcode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOpcode
            ? AppColors.accent.withValues(alpha: 0.14)
            : AppColors.surfaceAlt,
        border: Border.all(
          color: isOpcode
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isOpcode ? AppColors.accent : AppColors.codeBlue,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: isOpcode ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Execution pipeline indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PipelineSection extends StatelessWidget {
  const _PipelineSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Obx(() {
      final phase = c.phase.value;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PhaseNode(
              label: 'FETCH',
              active: phase == CpuPhase.fetch,
              done:
                  phase == CpuPhase.decode ||
                  phase == CpuPhase.execute ||
                  phase == CpuPhase.halted,
            ),
            _PipelineArrow(
              lit:
                  phase == CpuPhase.decode ||
                  phase == CpuPhase.execute ||
                  phase == CpuPhase.halted,
            ),
            _PhaseNode(
              label: 'DECODE',
              active: phase == CpuPhase.decode,
              done: phase == CpuPhase.execute || phase == CpuPhase.halted,
            ),
            _PipelineArrow(
              lit: phase == CpuPhase.execute || phase == CpuPhase.halted,
            ),
            _PhaseNode(
              label: 'EXECUTE',
              active: phase == CpuPhase.execute,
              done: phase == CpuPhase.halted,
            ),
          ],
        ),
      );
    });
  }
}

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (active) {
      borderColor = AppColors.accent;
      bgColor = AppColors.accent.withValues(alpha: 0.18);
      textColor = AppColors.accent;
    } else if (done) {
      borderColor = AppColors.accent.withValues(alpha: 0.28);
      bgColor = Colors.transparent;
      textColor = AppColors.accent.withValues(alpha: 0.55);
    } else {
      borderColor = AppColors.border;
      bgColor = Colors.transparent;
      textColor = AppColors.dimText;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PipelineArrow extends StatelessWidget {
  const _PipelineArrow({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 9,
        color: lit
            ? AppColors.accent.withValues(alpha: 0.55)
            : AppColors.dimText,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Mini register readout
// ─────────────────────────────────────────────────────────────────────────────

class _RegistersMiniSection extends StatelessWidget {
  const _RegistersMiniSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Obx(() {
      final regs = c.registers;
      final pc = c.pc.value;
      final ir = c.ir.value;
      final changed = c.changedRegisters;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MiniSectionLabel('REGISTERS'),
            const SizedBox(height: 8),
            ...regs.entries.map(
              (e) => _RegRow(
                name: e.key,
                value: e.value,
                changed: changed.contains(e.key),
              ),
            ),
            _RegRow(name: 'PC', value: pc, changed: changed.contains('PC')),
            const SizedBox(height: 12),
            const _MiniSectionLabel('INSTRUCTION REGISTER'),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: changed.contains('IR')
                    ? AppColors.changed.withValues(alpha: 0.10)
                    : AppColors.surfaceAlt,
                border: Border.all(
                  color: changed.contains('IR')
                      ? AppColors.changed
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ir.isEmpty ? '—' : ir,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MiniSectionLabel extends StatelessWidget {
  const _MiniSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.dimText,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _RegRow extends StatelessWidget {
  const _RegRow({
    required this.name,
    required this.value,
    required this.changed,
  });

  final String name;
  final int value;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final hexStr = name == 'PC'
        ? HexUtils.formatWord(value)
        : HexUtils.formatRegisterValue(name, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: changed
              ? AppColors.changed.withValues(alpha: 0.09)
              : AppColors.surfaceAlt,
          border: Border.all(
            color: changed ? AppColors.changed : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                name,
                style: TextStyle(
                  color: changed ? AppColors.changed : AppColors.mutedText,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$value',
                key: ValueKey('$name-$value'),
                style: TextStyle(
                  color: changed ? AppColors.changed : AppColors.text,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                hexStr,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: changed
                      ? AppColors.changed.withValues(alpha: 0.7)
                      : AppColors.dimText,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
