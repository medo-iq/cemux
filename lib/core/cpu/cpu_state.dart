import '../models/cpu_phase.dart';
import '../parser/parsed_instruction.dart';
import 'memory.dart';
import 'registers.dart';

class CpuState {
  CpuState({
    Registers? registers,
    Memory? memory,
    List<ParsedInstruction>? program,
  }) : registers = registers ?? Registers(),
       memory = memory ?? Memory(),
       program = program ?? const [];

  final Registers registers;
  final Memory memory;
  List<ParsedInstruction> program;
  CpuPhase phase = CpuPhase.idle;
  bool halted = false;
  ParsedInstruction? currentInstruction;
  int? currentLineIndex;
  String statusMessage = 'Load a program to begin.';
  final Set<String> changedRegisters = <String>{};
  final Set<int> readMemoryAddresses = <int>{};
  final Set<int> writtenMemoryAddresses = <int>{};

  void loadProgram(List<ParsedInstruction> instructions) {
    program = List.unmodifiable(instructions);
    resetRuntimeState();
    statusMessage =
        'Program loaded with ${instructions.length} instruction${instructions.length == 1 ? '' : 's'}.';
  }

  void resetRuntimeState() {
    registers.reset();
    memory.reset();
    phase = CpuPhase.idle;
    halted = false;
    currentInstruction = null;
    currentLineIndex = null;
    clearCycleMarkers();
  }

  void clearCycleMarkers() {
    changedRegisters.clear();
    readMemoryAddresses.clear();
    writtenMemoryAddresses.clear();
  }

  int readRegister(String name) => registers.read(name);

  void writeRegister(String name, int value) {
    registers.write(name, value);
    changedRegisters.add(name.toUpperCase());
  }

  int readMemory(int address) {
    final value = memory.read(address);
    readMemoryAddresses.add(address);
    return value;
  }

  void writeMemory(int address, int value) {
    memory.write(address, value);
    writtenMemoryAddresses.add(address);
  }

  Map<String, int> registerSnapshot() => registers.snapshot();

  List<int> memorySnapshot() => memory.snapshot();
}
