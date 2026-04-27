import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';
import 'operand_value.dart';

class SubHandler extends InstructionHandler {
  const SubHandler();

  @override
  String get mnemonic => 'SUB';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final destination = instruction.operands[0];
    final source = instruction.operands[1];
    final result = HexUtils.normalizeForRegister(
      destination,
      state.readRegister(destination) - readOperandValue(source, state),
    );
    state.writeRegister(destination, result);
    return InstructionResult(
      'Subtracted $source from $destination. $destination is now ${HexUtils.formatRegisterValue(destination, result)}.',
    );
  }
}
