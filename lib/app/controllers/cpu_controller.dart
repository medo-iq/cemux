import 'dart:async';

import 'package:get/get.dart';

import '../../config/demo_programs.dart';
import '../../core/cpu/cpu_engine.dart';
import '../../core/cpu/cpu_error.dart';
import '../../core/models/cpu_phase.dart';
import '../../core/models/execution_status.dart';
import '../../core/models/state_snapshot.dart';

class CpuController extends GetxController {
  CpuController({CpuEngine? engine}) : _engine = engine ?? CpuEngine();

  final CpuEngine _engine;
  Timer? _autoRunTimer;
  Timer? _highlightClearTimer;
  int _autoRunExecutedInstructions = 0;

  static const int maxAutoRunInstructions = 1000;
  static const double minPhaseDelayMs = 250;
  static const double maxPhaseDelayMs = 1500;
  static const double defaultPhaseDelayMs = 700;
  static const Duration highlightDuration = Duration(milliseconds: 520);

  final code = DemoPrograms.blankProgram.source.obs;
  final registers = <String, int>{
    'AX': 0,
    'BX': 0,
    'CX': 0,
    'DX': 0,
    'AH': 0,
    'AL': 0,
    'BH': 0,
    'BL': 0,
    'CH': 0,
    'CL': 0,
    'DH': 0,
    'DL': 0,
  }.obs;
  final pc = 0.obs;
  final ir = ''.obs;
  final memory = List<int>.filled(32, 0).obs;
  final instructionMemory = <String>[].obs;
  final currentInstruction = ''.obs;
  final phase = CpuPhase.idle.obs;
  final status = ExecutionStatus.idle.obs;
  final statusMessage =
      'Choose an example or write a program, then press Load.'.obs;
  final errorMessage = ''.obs;
  final currentLineIndex = RxnInt();
  final errorLineIndex = RxnInt();
  final changedRegisters = <String>{}.obs;
  final changedMemoryAddresses = <int>{}.obs;
  final selectedDemoName = DemoPrograms.blankProgram.name.obs;
  final phaseDelayMs = defaultPhaseDelayMs.obs;
  final isProgramLoaded = false.obs;
  final executionLog = <String>[].obs;
  final programCounterRegisterName = 'PC'.obs;

  List<DemoProgram> get demoPrograms => DemoPrograms.all;

  bool get canStep =>
      isProgramLoaded.value &&
      !status.value.isRunning &&
      status.value != ExecutionStatus.halted;

  bool get canRun =>
      isProgramLoaded.value &&
      !status.value.isRunning &&
      status.value != ExecutionStatus.halted;

  void updateCode(String value) {
    if (code.value == value) {
      return;
    }

    pause(markPaused: false);
    code.value = value;
    isProgramLoaded.value = false;
    status.value = ExecutionStatus.idle;
    phase.value = CpuPhase.idle;
    currentLineIndex.value = null;
    errorLineIndex.value = null;
    currentInstruction.value = '';
    errorMessage.value = '';
    statusMessage.value = 'Program changed. Press Load before execution.';
    _clearHighlights();
  }

  void selectDemo(DemoProgram program) {
    pause(markPaused: false);
    selectedDemoName.value = program.name;
    code.value = program.source;
    _engine.reset();
    isProgramLoaded.value = false;
    status.value = ExecutionStatus.idle;
    errorMessage.value = '';
    errorLineIndex.value = null;
    statusMessage.value = '${program.name} loaded into the editor. Press Load.';
    _syncFromEngine(showNextInstructionLine: false);
    _clearHighlights();
  }

  void setPhaseDelay(double value) {
    phaseDelayMs.value = value.clamp(minPhaseDelayMs, maxPhaseDelayMs);
  }

  void loadProgram() {
    _runSafely(() {
      pause(markPaused: false);
      _engine.loadProgram(code.value);
      isProgramLoaded.value = true;
      status.value = ExecutionStatus.loaded;
      errorMessage.value = '';
      errorLineIndex.value = null;
      executionLog.clear();
      _syncFromEngine(showNextInstructionLine: true);
      _clearHighlights();
    });
  }

  void step() {
    if (!canStep) {
      return;
    }

    _runSafely(() {
      final executed = _advanceOnePhase();
      if (executed) {
        _autoRunExecutedInstructions++;
      }
      final state = _engine.getState();
      status.value = state.halted
          ? ExecutionStatus.halted
          : ExecutionStatus.paused;
      _syncFromEngine(showNextInstructionLine: false);
    });
  }

  void run() {
    if (!canRun) {
      return;
    }

    _runSafely(() {
      status.value = ExecutionStatus.running;
      _autoRunExecutedInstructions = 0;
      _scheduleNextAutoStep();
    });
  }

  void pause({bool markPaused = true}) {
    _autoRunTimer?.cancel();
    _autoRunTimer = null;
    _engine.pause();
    if (markPaused && status.value == ExecutionStatus.running) {
      status.value = ExecutionStatus.paused;
      statusMessage.value = 'Execution paused.';
    }
  }

  void reset() {
    _runSafely(() {
      pause(markPaused: false);
      _engine.reset();
      isProgramLoaded.value = false;
      status.value = ExecutionStatus.idle;
      errorMessage.value = '';
      errorLineIndex.value = null;
      executionLog.clear();
      _syncFromEngine(showNextInstructionLine: false);
      _clearHighlights();
    });
  }

  void _scheduleNextAutoStep() {
    _autoRunTimer?.cancel();
    if (status.value != ExecutionStatus.running) {
      return;
    }

    _autoRunTimer = Timer(Duration(milliseconds: phaseDelayMs.value.round()), () {
      if (status.value != ExecutionStatus.running) {
        return;
      }

      _runSafely(() {
        if (_autoRunExecutedInstructions >= maxAutoRunInstructions) {
          pause(markPaused: false);
          throw const CpuExecutionException(
            'Auto-run stopped after 1000 executed instructions to prevent a possible infinite loop.',
          );
        }

        final executed = _advanceOnePhase();
        if (executed) {
          _autoRunExecutedInstructions++;
        }

        final state = _engine.getState();
        status.value = state.halted
            ? ExecutionStatus.halted
            : ExecutionStatus.running;
        _syncFromEngine(showNextInstructionLine: false);

        if (!state.halted) {
          _scheduleNextAutoStep();
        }
      });
    });
  }

  bool _advanceOnePhase() {
    final state = _engine.getState();
    switch (state.phase) {
      case CpuPhase.idle:
      case CpuPhase.execute:
        _engine.stepPhase();
        return false;
      case CpuPhase.fetch:
        _engine.stepPhase();
        return false;
      case CpuPhase.decode:
        final before = StateSnapshot.fromCpuState(state);
        _engine.stepPhase();
        _markChangesSince(before);
        final instr =
            _engine.getState().currentInstruction?.normalizedText ?? '';
        if (instr.isNotEmpty) {
          executionLog.insert(0, instr);
          if (executionLog.length > 24) executionLog.removeLast();
        }
        return true;
      case CpuPhase.halted:
        return false;
    }
  }

  void _runSafely(void Function() action) {
    try {
      errorMessage.value = '';
      action();
    } on CpuParseException catch (error) {
      pause(markPaused: false);
      status.value = ExecutionStatus.error;
      final hint = error.hint == null ? '' : '\nExpected form: ${error.hint}';
      errorMessage.value = '${error.message}$hint';
      errorLineIndex.value = error.lineNumber == null
          ? null
          : error.lineNumber! - 1;
      _syncFromEngine(showNextInstructionLine: false);
    } on CpuException catch (error) {
      pause(markPaused: false);
      status.value = ExecutionStatus.error;
      errorMessage.value = error.message;
      errorLineIndex.value = currentLineIndex.value;
      _syncFromEngine(showNextInstructionLine: false);
    } on Object catch (error) {
      pause(markPaused: false);
      status.value = ExecutionStatus.error;
      errorMessage.value = 'Unexpected error: $error';
      errorLineIndex.value = currentLineIndex.value;
      _syncFromEngine(showNextInstructionLine: false);
    }
  }

  void _markChangesSince(StateSnapshot before) {
    final state = _engine.getState();
    final nextChangedRegisters = <String>{};
    final currentRegisters = state.registerSnapshot();

    for (final entry in currentRegisters.entries) {
      if (before.registers[entry.key] != entry.value) {
        nextChangedRegisters.add(entry.key);
      }
    }

    if (before.pc != state.registers.pc) {
      nextChangedRegisters.add(state.registers.programCounterName);
    }

    if (before.ir != state.registers.ir) {
      nextChangedRegisters.add('IR');
    }

    final nextChangedMemory = <int>{};
    final currentMemory = state.memorySnapshot();
    for (var index = 0; index < currentMemory.length; index++) {
      if (before.memory[index] != currentMemory[index]) {
        nextChangedMemory.add(index);
      }
    }

    changedRegisters.assignAll(nextChangedRegisters);
    changedMemoryAddresses.assignAll(nextChangedMemory);

    _highlightClearTimer?.cancel();
    if (nextChangedRegisters.isNotEmpty || nextChangedMemory.isNotEmpty) {
      _highlightClearTimer = Timer(highlightDuration, _clearHighlights);
    }
  }

  void _clearHighlights() {
    _highlightClearTimer?.cancel();
    _highlightClearTimer = null;
    changedRegisters.clear();
    changedMemoryAddresses.clear();
  }

  void _syncFromEngine({required bool showNextInstructionLine}) {
    final state = _engine.getState();
    registers.assignAll(state.registerSnapshot());
    pc.value = state.registers.pc;
    ir.value = state.registers.ir;
    programCounterRegisterName.value = state.registers.programCounterName;
    memory.assignAll(state.memorySnapshot());
    instructionMemory.assignAll(
      state.program.map((instruction) => instruction.normalizedText),
    );
    currentInstruction.value = state.currentInstruction?.normalizedText ?? '';
    phase.value = state.phase;
    statusMessage.value = state.statusMessage;

    if (state.currentLineIndex != null) {
      currentLineIndex.value = state.currentLineIndex;
    } else if (showNextInstructionLine &&
        state.program.isNotEmpty &&
        state.registers.pc >= 0 &&
        state.registers.pc < state.program.length) {
      currentLineIndex.value =
          state.program[state.registers.pc].sourceLineNumber - 1;
    } else if (state.phase == CpuPhase.idle || state.phase == CpuPhase.halted) {
      currentLineIndex.value = null;
    }
  }

  @override
  void onClose() {
    _autoRunTimer?.cancel();
    _highlightClearTimer?.cancel();
    super.onClose();
  }
}
