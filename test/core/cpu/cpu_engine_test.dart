import 'package:cemux/core/cpu/cpu_engine.dart';
import 'package:cemux/core/cpu/cpu_error.dart';
import 'package:cemux/core/models/cpu_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CpuEngine', () {
    test('executes MOV, XCHG, ADD, and RET program', () {
      final engine = CpuEngine();

      engine.loadProgram('''
MOV AX,12CDH
MOV BX,2121H
XCHG AX,BX
ADD AX,BX
RET
''');

      final cycles = engine.run();

      expect(cycles, 5);
      expect(engine.state.readRegister('AX'), 0x33EE);
      expect(engine.state.readRegister('BX'), 0x12CD);
      expect(engine.state.halted, isTrue);
      expect(engine.state.phase, CpuPhase.halted);
    });

    test('executes 8086 arithmetic, logic, rotate, MUL, and DIV handlers', () {
      final engine = CpuEngine();

      engine.loadProgram('''
MOV AL,0FH
MOV BL,03H
AND AL,BL
OR AL,01H
XOR AL,05H
ROL AL,1
ROR AL,1
MOV AL,03H
MUL BL
DIV BL
RET
''');

      engine.run();

      expect(engine.state.readRegister('AL'), 3);
      expect(engine.state.readRegister('AH'), 0);
      expect(engine.state.readRegister('AX'), 9);
    });

    test('rejects invalid max cycle limits', () {
      final engine = CpuEngine();

      engine.loadProgram('MOV AX,1H');

      expect(
        () => engine.run(maxCycles: 0),
        throwsA(isA<CpuExecutionException>()),
      );
    });

    test('stepPhase advances one visible CPU phase at a time', () {
      final engine = CpuEngine();

      engine.loadProgram('MOV AX,4H');

      engine.stepPhase();

      expect(engine.state.phase, CpuPhase.fetch);
      expect(engine.state.registers.ir, 'MOV AX,4H');

      engine.stepPhase();

      expect(engine.state.phase, CpuPhase.decode);

      engine.stepPhase();

      expect(engine.state.phase, CpuPhase.halted);
      expect(engine.state.readRegister('AX'), 4);
    });

    test('default engine exposes Intel 8086 registers', () {
      final engine = CpuEngine();

      final registers = engine.getState().registerSnapshot();

      expect(registers.keys, containsAll(['AX', 'BX', 'CX', 'DX']));
      expect(registers.keys, containsAll(['AH', 'AL', 'BH', 'BL']));
      expect(registers.keys, containsAll(['CH', 'CL', 'DH', 'DL']));
      expect(engine.getState().registers.programCounterName, 'PC');
    });

    test('Intel 8086 engine executes minimal native register program', () {
      final engine = CpuEngine.intel8086();

      engine.loadProgram('''
MOV AX,10H
MOV BX,5H
ADD AX,BX
RET
''');

      engine.run();

      expect(engine.state.readRegister('AX'), 0x15);
      expect(engine.state.readRegister('BX'), 5);
      expect(engine.state.registers.pc, 4);
    });
  });
}
