import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';

class IncHandler extends InstructionHandler {
  const IncHandler();

  @override
  String get mnemonic => 'INC';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final register = instruction.operands[0];
    final result = HexUtils.normalizeForRegister(
      register,
      state.readRegister(register) + 1,
    );
    state.writeRegister(register, result);
    return InstructionResult(
      'Incremented $register to ${HexUtils.formatRegisterValue(register, result)}.',
    );
  }
}
