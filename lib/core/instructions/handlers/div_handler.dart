import '../../cpu/cpu_error.dart';
import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';
import '../../parser/parsed_instruction.dart';
import '../instruction_handler.dart';
import 'operand_value.dart';

class DivHandler extends InstructionHandler {
  const DivHandler();

  @override
  String get mnemonic => 'DIV';

  @override
  InstructionResult execute(ParsedInstruction instruction, CpuState state) {
    final source = instruction.operands[0];
    final divisor = readOperandValue(source, state);
    if (divisor == 0) {
      throw const CpuExecutionException('DIV cannot divide by zero.');
    }

    final dividend = state.readRegister('AX');
    final quotient = dividend ~/ divisor;
    final remainder = dividend % divisor;
    state.writeRegister('AL', HexUtils.normalizeForRegister('AL', quotient));
    state.writeRegister('AH', HexUtils.normalizeForRegister('AH', remainder));
    return InstructionResult(
      'Divided AX by $source. AL holds quotient and AH holds remainder.',
    );
  }
}
