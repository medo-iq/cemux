import '../instructions/instruction_registry.dart';
import '../models/cpu_phase.dart';
import '../parser/program_parser.dart';
import 'cpu_engine.dart';
import 'cpu_error.dart';
import 'cpu_state.dart';

class SimpleCpuEngine implements CpuEngine {
  SimpleCpuEngine({
    ProgramParser? parser,
    InstructionRegistry? registry,
    CpuState? state,
  }) : _parser = parser ?? ProgramParser(),
       _registry = registry ?? InstructionRegistry.mvp(),
       _state = state ?? CpuState();

  final ProgramParser _parser;
  final InstructionRegistry _registry;
  final CpuState _state;

  @override
  CpuState getState() => _state;

  @override
  CpuState get state => _state;

  @override
  void loadProgram(String source) {
    final program = _parser.parse(source);
    _state.loadProgram(program);
  }

  @override
  void reset() {
    _state.resetRuntimeState();
    _state.statusMessage = 'CPU reset. Load a program to begin.';
  }

  void step() {
    fetchPhase();
    decodePhase();
    executePhase();
  }

  @override
  void stepPhase() {
    switch (_state.phase) {
      case CpuPhase.idle:
      case CpuPhase.execute:
        fetchPhase();
        break;
      case CpuPhase.fetch:
        decodePhase();
        break;
      case CpuPhase.decode:
        executePhase();
        break;
      case CpuPhase.halted:
        break;
    }
  }

  @override
  int run({int maxCycles = 1000}) {
    if (maxCycles <= 0) {
      throw const CpuExecutionException(
        'Max cycles must be greater than zero.',
      );
    }

    var cycles = 0;
    while (!_state.halted && cycles < maxCycles) {
      step();
      cycles++;
    }

    if (!_state.halted) {
      throw CpuExecutionException(
        'Execution stopped after $maxCycles cycles to prevent a possible infinite loop.',
      );
    }

    return cycles;
  }

  @override
  void pause() {}

  void fetchPhase() {
    if (!_ensureCanStep()) {
      return;
    }

    _state.clearCycleMarkers();
    _state.phase = CpuPhase.fetch;

    final pc = _state.registers.pc;
    if (pc < 0 || pc >= _state.program.length) {
      _state.halted = true;
      _state.phase = CpuPhase.halted;
      _state.currentInstruction = null;
      _state.currentLineIndex = null;
      _state.statusMessage =
          'Program halted. PC points outside the loaded program.';
      return;
    }

    final instruction = _state.program[pc];
    _state.currentInstruction = instruction;
    _state.currentLineIndex = instruction.sourceLineNumber - 1;
    _state.registers.ir = instruction.normalizedText;
    _state.registers.pc = pc + 1;
    _state.registers.syncProgramCounterRegister();
    _state.changedRegisters.addAll({
      'IR',
      'PC',
      _state.registers.programCounterName,
    });
    _state.statusMessage = 'Reading instruction from memory at PC $pc.';
  }

  void decodePhase() {
    if (!_ensureCanStep()) {
      return;
    }

    if (_state.halted || _state.currentInstruction == null) {
      return;
    }

    _state.phase = CpuPhase.decode;
    final instruction = _state.currentInstruction!;
    _state.statusMessage =
        'Decoding instruction: ${instruction.normalizedText}.';
  }

  void executePhase() {
    if (!_ensureCanStep()) {
      return;
    }

    if (_state.halted || _state.currentInstruction == null) {
      return;
    }

    _state.phase = CpuPhase.execute;
    final instruction = _state.currentInstruction!;
    final handler = _registry.resolve(instruction.mnemonic);
    final result = handler.execute(instruction, _state);
    _state.registers.syncProgramCounterRegister();
    _state.statusMessage = result.message;
    _haltIfProgramCompleted();
  }

  void _haltIfProgramCompleted() {
    if (!_state.halted && _state.registers.pc >= _state.program.length) {
      _state.halted = true;
      _state.phase = CpuPhase.halted;
      _state.statusMessage = '${_state.statusMessage} Program completed.';
    }
  }

  bool _ensureCanStep() {
    if (_state.program.isEmpty) {
      throw const CpuExecutionException(
        'No program loaded. Press Load before stepping.',
      );
    }

    if (_state.halted) {
      _state.phase = CpuPhase.halted;
      _state.statusMessage = 'Program already halted.';
      return false;
    }

    return true;
  }
}
