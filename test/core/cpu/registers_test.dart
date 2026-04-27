import 'package:cemux/core/cpu/cpu_error.dart';
import 'package:cemux/core/cpu/registers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Registers', () {
    test('starts with zeroed general registers and empty IR', () {
      final registers = Registers();

      expect(
        registers.snapshot().keys,
        containsAll(['AX', 'BX', 'CX', 'DX', 'AH', 'AL', 'BH', 'BL']),
      );
      expect(registers.pc, 0);
      expect(registers.ir, '');
    });

    test('reads and writes general registers case-insensitively', () {
      final registers = Registers();

      registers.write('ax', 42);

      expect(registers.read('AX'), 42);
      expect(registers.snapshot()['AX'], 42);
    });

    test('rejects unknown registers', () {
      final registers = Registers();

      expect(
        () => registers.write('R1', 1),
        throwsA(isA<CpuExecutionException>()),
      );
    });
  });
}
