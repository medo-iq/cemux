import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cpu_controller.dart';
import '../../colors/app_colors.dart';
import '../../config/demo_programs.dart';
import '../../core/models/execution_status.dart';
import '../../core/models/cpu_phase.dart';

/// Full-height IDE toolbar that houses all execution controls.
class CemuxToolbar extends StatelessWidget {
  const CemuxToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CpuController>();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width,
            ),
            child: _buildRow(c),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(CpuController c) {
    final isRunning = c.status.value.isRunning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Brand ─────────────────────────────────────────────────────────
        const _Brand(),
        const _VSep(),

        // ── Program section ───────────────────────────────────────────────
        _ToolbarDemoDropdown(
          programs: c.demoPrograms,
          selectedName: c.selectedDemoName.value,
          enabled: !isRunning,
          onSelected: c.selectDemo,
        ),
        const SizedBox(width: 2),
        _ToolbarBtn(
          icon: Icons.note_add_outlined,
          label: 'New',
          enabled: !isRunning,
          onTap: () => c.updateCode(''),
        ),
        _ToolbarBtn(
          icon: Icons.upload_file_outlined,
          label: 'Load',
          accent: true,
          enabled: !isRunning,
          onTap: c.loadProgram,
        ),
        const _VSep(),

        // ── Execution controls ────────────────────────────────────────────
        _ToolbarBtn(
          icon: Icons.skip_next_rounded,
          label: 'Step',
          enabled: c.canStep,
          onTap: c.step,
        ),
        _ToolbarBtn(
          icon: Icons.play_arrow_rounded,
          label: 'Run',
          accent: true,
          enabled: c.canRun,
          onTap: c.run,
        ),
        _ToolbarBtn(
          icon: Icons.pause_rounded,
          label: 'Pause',
          enabled: isRunning,
          onTap: c.pause,
        ),
        _ToolbarBtn(
          icon: Icons.refresh_rounded,
          label: 'Reset',
          enabled: !isRunning,
          onTap: c.reset,
        ),
        const _VSep(),

        // ── Status badge (right side) ─────────────────────────────────────
        _StatusBadge(status: c.status.value, phase: c.phase.value),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '8086 Assembly Simulator',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: 10),
          const Text(
            'Memory - Registers - PC - IR',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VSep extends StatelessWidget {
  const _VSep();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.border,
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ? AppColors.accent : AppColors.mutedText;
    final textColor = accent ? AppColors.accent : AppColors.text;

    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppColors.surfaceAlt.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
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

class _ToolbarDemoDropdown extends StatelessWidget {
  const _ToolbarDemoDropdown({
    required this.programs,
    required this.selectedName,
    required this.enabled,
    required this.onSelected,
  });

  final List<DemoProgram> programs;
  final String selectedName;
  final bool enabled;
  final ValueChanged<DemoProgram> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = programs.firstWhere(
      (p) => p.name == selectedName,
      orElse: () => programs.first,
    );

    return Container(
      height: 30,
      width: 158,
      margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DemoProgram>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(6),
          dropdownColor: AppColors.surfaceAlt,
          iconSize: 14,
          isDense: true,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
          onChanged: enabled
              ? (p) {
                  if (p != null) onSelected(p);
                }
              : null,
          items: programs
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.phase});

  final ExecutionStatus status;
  final CpuPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _info();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _info() {
    switch (status) {
      case ExecutionStatus.idle:
        return ('IDLE', AppColors.mutedText);
      case ExecutionStatus.loaded:
        return ('LOADED', AppColors.accentBlue);
      case ExecutionStatus.running:
        return ('RUNNING', AppColors.accent);
      case ExecutionStatus.paused:
        return ('PAUSED', AppColors.changed);
      case ExecutionStatus.halted:
        return ('HALTED', AppColors.success);
      case ExecutionStatus.error:
        return ('ERROR', AppColors.danger);
    }
  }
}
