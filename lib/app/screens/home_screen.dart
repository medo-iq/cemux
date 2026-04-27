import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import '../../features/editor/code_editor_panel.dart';
import '../../features/quick_panel/quick_panel.dart';
import '../../features/right_panel/right_panel.dart';
import '../widgets/cemux_toolbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — 2-zone layout: editor | control panel
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          CemuxToolbar(),
          Expanded(child: _MainContent()),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return const _StackedLayout();
        }
        return const _SideBySideLayout();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop — resizable split: editor | draggable divider | right panel
// ─────────────────────────────────────────────────────────────────────────────

class _SideBySideLayout extends StatefulWidget {
  const _SideBySideLayout();

  @override
  State<_SideBySideLayout> createState() => _SideBySideLayoutState();
}

class _SideBySideLayoutState extends State<_SideBySideLayout> {
  static const double _minRightWidth = 220.0;
  static const double _maxRightFraction = 0.60;
  static const double _defaultRightWidth = 320.0;

  double _rightWidth = _defaultRightWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Reserve space for the quick-insert palette on the left.
        final available = totalWidth - QuickPanel.panelWidth;
        final maxRight = available * _maxRightFraction;
        final rightWidth = _rightWidth.clamp(_minRightWidth, maxRight);
        final editorWidth = available - rightWidth - _ResizableDivider.width;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone 0 — quick-insert palette
            const QuickPanel(),
            // Zone 1 — code editor
            SizedBox(
              width: editorWidth,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: CodeEditorPanel(),
              ),
            ),
            // Draggable divider
            _ResizableDivider(
              onDelta: (dx) => setState(() {
                _rightWidth = (_rightWidth - dx).clamp(
                  _minRightWidth,
                  available * _maxRightFraction,
                );
              }),
            ),
            // Zone 2 — inspector panel
            SizedBox(width: rightWidth, child: const RightPanel()),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable resize handle
// ─────────────────────────────────────────────────────────────────────────────

class _ResizableDivider extends StatefulWidget {
  const _ResizableDivider({required this.onDelta});

  /// Total hit-area width (transparent zone the user can grab).
  static const double width = 8.0;

  final ValueChanged<double> onDelta;

  @override
  State<_ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<_ResizableDivider> {
  bool _hovering = false;
  bool _dragging = false;

  bool get _active => _hovering || _dragging;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDelta(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        child: SizedBox(
          width: _ResizableDivider.width,
          child: Stack(
            children: [
              // Visible line — 1 px at rest, 2 px while active
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _active ? 2.0 : 1.0,
                  color: _active
                      ? AppColors.accent.withValues(alpha: 0.70)
                      : AppColors.border,
                ),
              ),
              // Grip dots — fade in on hover / drag
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _active ? 1.0 : 0.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < 2) const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile — editor top · control panel bottom
// ─────────────────────────────────────────────────────────────────────────────

class _StackedLayout extends StatelessWidget {
  const _StackedLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone 1
        const Expanded(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: CodeEditorPanel(),
          ),
        ),
        Container(height: 1, color: AppColors.border),
        // Zone 2
        const SizedBox(height: 300, child: RightPanel()),
      ],
    );
  }
}
