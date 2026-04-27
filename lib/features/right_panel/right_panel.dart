import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/controllers/cpu_controller.dart';
import '../../colors/app_colors.dart';
import '../../core/cpu/hex_utils.dart';
import '../../core/models/cpu_phase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RightPanel — unified debugger inspector
// Vertical layout (top → bottom): CPU Info · Registers · Memory
// ─────────────────────────────────────────────────────────────────────────────

class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CpuInfoSection(),
            _SectionDivider(),
            _RegistersSection(),
            _SectionDivider(),
            _InstructionMemorySection(),
            _SectionDivider(),
            _MemorySection(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared structural primitives
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.dimText,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Divider(height: 1, color: AppColors.border),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — CPU Info
// Phase pill · current instruction · explanation · pipeline flow
// ─────────────────────────────────────────────────────────────────────────────

class _CpuInfoSection extends StatelessWidget {
  const _CpuInfoSection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Obx(() {
      final phase = c.phase.value;
      final instruction = c.currentInstruction.value;
      final hasError = c.errorMessage.value.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: label + phase pill + running dot ──────────
            Row(
              children: [
                const Expanded(child: _SectionLabel('CPU INFO')),
                _PhasePill(phase: phase),
                if (c.status.value.isRunning) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // ── Content: error / instruction+explanation / idle msg ───
            if (hasError)
              Text(
                c.errorMessage.value,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              )
            else if (instruction.isNotEmpty) ...[
              _InstructionTokens(instruction: instruction),
              const SizedBox(height: 6),
              Text(
                _explain(instruction, phase, c),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ] else
              Text(
                c.statusMessage.value,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 14),

            // ── Pipeline flow: FETCH → DECODE → EXECUTE ───────────────
            _PipelineFlow(phase: phase),
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
        return _execExpl(instr);
      case CpuPhase.halted:
        return 'Program finished execution';
      case CpuPhase.idle:
        return c.statusMessage.value;
    }
  }

  String _execExpl(String instr) {
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
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

  Color _color(CpuPhase p) => switch (p) {
    CpuPhase.fetch => AppColors.accentBlue,
    CpuPhase.decode => AppColors.accent,
    CpuPhase.execute => AppColors.changed,
    CpuPhase.halted => AppColors.success,
    CpuPhase.idle => AppColors.dimText,
  };
}

// ─── Instruction token chips ──────────────────────────────────────────────────

class _InstructionTokens extends StatelessWidget {
  const _InstructionTokens({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    final parts = instruction.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 5,
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

// ─── Pipeline flow indicator ──────────────────────────────────────────────────

class _PipelineFlow extends StatelessWidget {
  const _PipelineFlow({required this.phase});

  final CpuPhase phase;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        _Arrow(
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
        _Arrow(lit: phase == CpuPhase.execute || phase == CpuPhase.halted),
        _PhaseNode(
          label: 'EXECUTE',
          active: phase == CpuPhase.execute,
          done: phase == CpuPhase.halted,
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _Arrow extends StatelessWidget {
  const _Arrow({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Icon(
      Icons.arrow_forward_ios_rounded,
      size: 9,
      color: lit ? AppColors.accent.withValues(alpha: 0.55) : AppColors.dimText,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Registers
// Table: REG | DEC | HEX  ·  IR box below
// ─────────────────────────────────────────────────────────────────────────────

class _RegistersSection extends StatelessWidget {
  const _RegistersSection();

  static const _colStyle = TextStyle(
    color: AppColors.dimText,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Obx(() {
      final regs = c.registers;
      final pc = c.pc.value;
      final ir = c.ir.value;
      final changed = c.changedRegisters;
      final gpEntries = regs.entries.toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionLabel('REGISTERS'),
            const SizedBox(height: 8),

            // Column labels
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(width: 36, child: Text('REG', style: _colStyle)),
                  Expanded(child: Text('DEC', style: _colStyle)),
                  SizedBox(
                    width: 68,
                    child: Text(
                      'HEX',
                      style: _colStyle,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // General-purpose registers
            ...gpEntries.asMap().entries.map(
              (e) => _RegRow(
                name: e.value.key,
                decValue: '${e.value.value}',
                hexValue: _hex(e.value.key, e.value.value),
                changed: changed.contains(e.value.key),
                isEven: e.key.isEven,
              ),
            ),

            // Program counter
            _RegRow(
              name: 'PC',
              decValue: '$pc',
              hexValue: HexUtils.formatWord(pc),
              changed: changed.contains('PC'),
              isEven: gpEntries.length.isEven,
              isSpecial: true,
            ),

            const SizedBox(height: 10),
            const _SectionLabel('INSTRUCTION REGISTER'),
            const SizedBox(height: 5),
            _IrBox(ir: ir, changed: changed.contains('IR')),
          ],
        ),
      );
    });
  }

  static String _hex(String registerName, int value) {
    return HexUtils.formatRegisterValue(registerName, value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Instruction Memory
// Shows the loaded program as memory-addressed assembly instructions.
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionMemorySection extends StatelessWidget {
  const _InstructionMemorySection();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Obx(() {
        final instructions = c.instructionMemory;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: _SectionLabel('INSTRUCTION MEMORY')),
                Text(
                  '${instructions.length} instructions',
                  style: const TextStyle(color: AppColors.dimText, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (instructions.isEmpty)
              const Text(
                'Load a program to show instruction memory.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < instructions.length; i++)
                      _InstructionMemoryRow(
                        address: i,
                        instruction: instructions[i],
                        active:
                            c.pc.value == i || c.currentLineIndex.value == i,
                        isEven: i.isEven,
                      ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _InstructionMemoryRow extends StatelessWidget {
  const _InstructionMemoryRow({
    required this.address,
    required this.instruction,
    required this.active,
    required this.isEven,
  });

  final int address;
  final String instruction;
  final bool active;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.13)
            : isEven
            ? AppColors.surface
            : AppColors.surfaceAlt.withValues(alpha: 0.35),
        border: Border(
          left: BorderSide(
            color: active ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              HexUtils.formatWord(address),
              style: TextStyle(
                color: active ? AppColors.accent : AppColors.mutedText,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? AppColors.accent : AppColors.text,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegRow extends StatelessWidget {
  const _RegRow({
    required this.name,
    required this.decValue,
    required this.hexValue,
    required this.changed,
    required this.isEven,
    this.isSpecial = false,
  });

  final String name;
  final String decValue;
  final String hexValue;
  final bool changed;
  final bool isEven;
  final bool isSpecial;

  @override
  Widget build(BuildContext context) {
    final bgColor = changed
        ? AppColors.changed.withValues(alpha: 0.09)
        : isEven
        ? AppColors.surface
        : AppColors.surfaceAlt.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: changed
              ? AppColors.changed.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              name,
              style: TextStyle(
                color: changed
                    ? AppColors.changed
                    : isSpecial
                    ? AppColors.accentBlue
                    : AppColors.accent,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                decValue,
                key: ValueKey('dec-$name-$decValue'),
                style: TextStyle(
                  color: changed ? AppColors.changed : AppColors.text,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                hexValue,
                key: ValueKey('hex-$name-$hexValue'),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: changed
                      ? AppColors.changed.withValues(alpha: 0.8)
                      : AppColors.dimText,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IrBox extends StatelessWidget {
  const _IrBox({required this.ir, required this.changed});

  final String ir;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: changed
            ? AppColors.changed.withValues(alpha: 0.10)
            : AppColors.surfaceAlt,
        border: Border.all(
          color: changed ? AppColors.changed : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ir.isEmpty ? '—' : ir,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: changed ? AppColors.changed : AppColors.text,
          fontWeight: changed ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Memory (expandable)
// Shows first 16 addresses by default; "Show More" reveals the rest.
// Dynamic: adapts to any controller.memory.length without hardcoding.
// ─────────────────────────────────────────────────────────────────────────────

class _MemorySection extends StatefulWidget {
  const _MemorySection();

  @override
  State<_MemorySection> createState() => _MemorySectionState();
}

class _MemorySectionState extends State<_MemorySection> {
  bool _expanded = false;
  static const _defaultCount = 16;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Obx(() {
        final memory = c.memory;
        final changed = c.changedMemoryAddresses;
        final total = memory.length;
        final visible = _expanded ? total : _defaultCount.clamp(0, total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: label + total cell count
            Row(
              children: [
                const Expanded(child: _SectionLabel('MEMORY')),
                Text(
                  '$total cells',
                  style: const TextStyle(color: AppColors.dimText, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Column labels
            const _MemoryColumnHeader(),
            const SizedBox(height: 3),

            // Memory rows — ListView.builder for clean item separation
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible,
              itemBuilder: (_, i) => _MemoryRow(
                index: i,
                value: memory[i],
                changed: changed.contains(i),
                isEven: i.isEven,
              ),
            ),

            // Expand / collapse toggle
            if (total > _defaultCount)
              _ExpandButton(
                expanded: _expanded,
                remaining: total - _defaultCount,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),

            const SizedBox(height: 4),
          ],
        );
      }),
    );
  }
}

// ─── Memory column header ────────────────────────────────────────────────────

class _MemoryColumnHeader extends StatelessWidget {
  const _MemoryColumnHeader();

  static const _style = TextStyle(
    color: AppColors.dimText,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text('ADDR', style: _style)),
          Expanded(child: Text('DEC', style: _style)),
          SizedBox(width: 52, child: Text('HEX', style: _style)),
          SizedBox(width: 24), // state dot column — no label needed
        ],
      ),
    );
  }
}

// ─── Memory row ───────────────────────────────────────────────────────────────

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({
    required this.index,
    required this.value,
    required this.changed,
    required this.isEven,
  });

  final int index;
  final int value;
  final bool changed;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final bg = changed
        ? AppColors.changed.withValues(alpha: 0.09)
        : isEven
        ? AppColors.surface
        : AppColors.surfaceAlt.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(
            color: changed ? AppColors.changed : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          // Address
          SizedBox(
            width: 52,
            child: Text(
              _hexAddr(index),
              style: TextStyle(
                color: changed ? AppColors.changed : AppColors.mutedText,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          // Decimal value
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '$value',
                key: ValueKey('mdec-$index-$value'),
                style: TextStyle(
                  color: changed ? AppColors.changed : AppColors.text,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          // Hex value
          SizedBox(
            width: 52,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _hexVal(value),
                key: ValueKey('mhex-$index-$value'),
                style: TextStyle(
                  color: changed
                      ? AppColors.changed.withValues(alpha: 0.8)
                      : AppColors.dimText,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // Written indicator dot
          SizedBox(
            width: 24,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: changed
                    ? Container(
                        key: const ValueKey('dot-on'),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.changed,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('dot-off'),
                        width: 6,
                        height: 6,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _hexAddr(int i) => HexUtils.formatWord(i);

  static String _hexVal(int v) {
    return HexUtils.formatWord(v);
  }
}

// ─── Expand / collapse button ────────────────────────────────────────────────

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({
    required this.expanded,
    required this.remaining,
    required this.onToggle,
  });

  final bool expanded;
  final int remaining;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 5),
              Text(
                expanded ? 'Show Less' : 'Show +$remaining More',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
