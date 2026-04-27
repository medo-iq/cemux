import '../parser/program_parser.dart';
import 'cpu_state.dart';
import 'registers.dart';
import 'simple_cpu_engine.dart';

class Intel8086Engine extends SimpleCpuEngine {
  Intel8086Engine()
    : super(
        parser: ProgramParser(registerNames: _supportedRegisters),
        state: CpuState(
          registers: Registers(names: _registers, programCounterName: 'PC'),
        ),
      );

  static const _registers = [
    'AX',
    'BX',
    'CX',
    'DX',
    'AH',
    'AL',
    'BH',
    'BL',
    'CH',
    'CL',
    'DH',
    'DL',
  ];
  static const _supportedRegisters = _registers;
}
