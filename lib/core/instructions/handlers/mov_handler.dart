import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';
import 'operand_value.dart';

class MovHandler extends InstructionHandler {
  const MovHandler();

  @override
  String get mnemonic => 'MOV';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final destination = instruction.operands[0];
    final source = instruction.operands[1];
    final value = readOperandValue(source, state);
    final normalized = HexUtils.normalizeForRegister(destination, value);
    state.writeRegister(destination, normalized);
    return InstructionResult(
      'Moved ${HexUtils.formatRegisterValue(destination, normalized)} into $destination.',
    );
  }
}
