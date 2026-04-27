import '../cpu/cpu_state.dart';
import '../parser/parsed_instruction.dart';

class InstructionResult {
  const InstructionResult(this.message);

  final String message;
}

abstract class InstructionHandler {
  const InstructionHandler();

  String get mnemonic;

  InstructionResult execute(ParsedInstruction instruction, CpuState state);
}
