import '../../cpu/cpu_state.dart';
import '../../cpu/hex_utils.dart';

int readOperandValue(String operand, CpuState state) {
  final normalized = operand.toUpperCase();
  if (HexUtils.isRegister(normalized)) {
    return state.readRegister(normalized);
  }

  final value = HexUtils.parseImmediate(normalized);
  if (value == null) {
    throw StateError('Invalid operand value: $operand');
  }
  return value;
}
