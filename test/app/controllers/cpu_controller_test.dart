import 'package:cemux/app/controllers/cpu_controller.dart';
import 'package:cemux/config/demo_programs.dart';
import 'package:cemux/core/models/cpu_phase.dart';
import 'package:cemux/core/models/execution_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CpuController phase stepping', () {
    test('Step advances fetch, decode, then execute visibly', () {
      final controller = CpuController();
      addTearDown(controller.onClose);

      controller.selectDemo(DemoPrograms.exchangeAndAdd);
      controller.loadProgram();

      expect(controller.status.value, ExecutionStatus.loaded);
      expect(controller.phase.value, CpuPhase.idle);
      expect(controller.currentLineIndex.value, 0);

      controller.step();

      expect(controller.phase.value, CpuPhase.fetch);
      expect(controller.ir.value, 'MOV AX,12CDH');
      expect(controller.pc.value, 1);
      expect(controller.currentLineIndex.value, 0);

      controller.step();

      expect(controller.phase.value, CpuPhase.decode);
      expect(controller.statusMessage.value, contains('Decoding instruction'));

      controller.step();

      expect(controller.phase.value, CpuPhase.execute);
      expect(controller.registers['AX'], 0x12CD);
      expect(controller.changedRegisters, contains('AX'));
    });

    test('loadProgram exposes parser error line for editor feedback', () {
      final controller = CpuController();
      addTearDown(controller.onClose);

      controller.updateCode('MOV AX\nADD AX,BX');
      controller.loadProgram();

      expect(controller.errorMessage.value, contains('Expected form'));
      expect(controller.errorLineIndex.value, 0);
    });

    test('starts with a blank editor demo selected', () {
      final controller = CpuController();
      addTearDown(controller.onClose);

      expect(controller.selectedDemoName.value, DemoPrograms.blankProgram.name);
      expect(controller.code.value, isEmpty);
      expect(controller.isProgramLoaded.value, isFalse);
    });

    test('uses Intel 8086 register profile by default', () {
      final controller = CpuController();
      addTearDown(controller.onClose);

      expect(controller.registers.keys, containsAll(['AX', 'BX', 'AH', 'AL']));
      expect(controller.programCounterRegisterName.value, 'PC');
      expect(controller.isProgramLoaded.value, isFalse);
    });
  });
}
