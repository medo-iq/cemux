import 'package:cemux/core/cpu/cpu_error.dart';
import 'package:cemux/core/parser/program_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgramParser', () {
    test('parses supported instructions and preserves source line numbers', () {
      final parser = ProgramParser();

      final program = parser.parse('''
; comment
mov ax,12cdh
ADD ax,bx # inline comment
RET
''');

      expect(program, hasLength(3));
      expect(program[0].mnemonic, 'MOV');
      expect(program[0].operands, ['AX', '12CDH']);
      expect(program[0].sourceLineNumber, 2);
      expect(program[1].normalizedText, 'ADD AX,BX');
      expect(program[2].sourceLineNumber, 4);
    });

    test('rejects unsupported instructions', () {
      final parser = ProgramParser();

      expect(
        () => parser.parse('LOAD R1 5'),
        throwsA(isA<CpuParseException>()),
      );
    });

    test('rejects malformed operands', () {
      final parser = ProgramParser();

      expect(
        () => parser.parse('MOV RX,5H'),
        throwsA(isA<CpuParseException>()),
      );
      expect(() => parser.parse('ROL AL,2'), throwsA(isA<CpuParseException>()));
    });

    test('reports line number and expected form for educational errors', () {
      final parser = ProgramParser();

      expect(
        () => parser.parse('MOV AX'),
        throwsA(
          isA<CpuParseException>()
              .having((error) => error.lineNumber, 'lineNumber', 1)
              .having((error) => error.hint, 'hint', 'MOV AX,12CDH'),
        ),
      );
    });
  });
}
