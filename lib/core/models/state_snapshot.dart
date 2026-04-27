import '../cpu/cpu_state.dart';

class StateSnapshot {
  const StateSnapshot({
    required this.registers,
    required this.pc,
    required this.ir,
    required this.memory,
  });

  factory StateSnapshot.fromCpuState(CpuState state) {
    return StateSnapshot(
      registers: state.registerSnapshot(),
      pc: state.registers.pc,
      ir: state.registers.ir,
      memory: state.memorySnapshot(),
    );
  }

  final Map<String, int> registers;
  final int pc;
  final String ir;
  final List<int> memory;
}
