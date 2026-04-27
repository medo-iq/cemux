import '../../cpu/cpu_state.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';

class XchgHandler extends InstructionHandler {
  const XchgHandler();

  @override
  String get mnemonic => 'XCHG';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final first = instruction.operands[0];
    final second = instruction.operands[1];
    final firstValue = state.readRegister(first);
    final secondValue = state.readRegister(second);
    state.writeRegister(first, secondValue);
    state.writeRegister(second, firstValue);
    return InstructionResult('Exchanged values between $first and $second.');
  }
}
