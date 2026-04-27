import 'package:cemux/core/cpu/cpu_error.dart';
import 'package:cemux/core/cpu/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Memory', () {
    test('starts with 32 zeroed cells by default', () {
      final memory = Memory();

      expect(memory.size, 32);
      expect(memory.snapshot(), everyElement(0));
    });

    test('reads and writes values by address', () {
      final memory = Memory();

      memory.write(31, 99);

      expect(memory.read(31), 99);
    });

    test('rejects addresses outside memory bounds', () {
      final memory = Memory();

      expect(() => memory.read(-1), throwsA(isA<CpuExecutionException>()));
      expect(() => memory.write(32, 1), throwsA(isA<CpuExecutionException>()));
    });
  });
}
