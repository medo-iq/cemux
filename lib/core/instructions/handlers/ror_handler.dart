import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';

class RorHandler extends InstructionHandler {
  const RorHandler();

  @override
  String get mnemonic => 'ROR';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final register = instruction.operands[0];
    final mask = HexUtils.maskForRegister(register);
    final width = mask == 0xFF ? 8 : 16;
    final value = state.readRegister(register) & mask;
    final result = ((value >> 1) | ((value & 1) << (width - 1))) & mask;
    state.writeRegister(register, result);
    return InstructionResult(
      'Rotated $register right by 1. $register is now ${HexUtils.formatRegisterValue(register, result)}.',
    );
  }
}
