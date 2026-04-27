import '../../cpu/cpu_state.dart';
import '../../models/cpu_phase.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';

class RetHandler extends InstructionHandler {
  const RetHandler();

  @override
  String get mnemonic => 'RET';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    state.halted = true;
    state.phase = CpuPhase.halted;
    return const InstructionResult('RET reached. Program returned.');
  }
}
