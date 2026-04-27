import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';
import 'operand_value.dart';

class MulHandler extends InstructionHandler {
  const MulHandler();

  @override
  String get mnemonic => 'MUL';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final source = instruction.operands[0];
    final result = HexUtils.normalizeForRegister(
      'AX',
      state.readRegister('AL') * readOperandValue(source, state),
    );
    state.writeRegister('AX', result);
    return InstructionResult(
      'Multiplied AL by $source. AX is now ${HexUtils.formatRegisterValue('AX', result)}.',
    );
  }
}
