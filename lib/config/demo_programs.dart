class DemoProgram {
  const DemoProgram({required this.name, required this.source});

  final String name;
  final String source;
}

class DemoPrograms {
  const DemoPrograms._();

  static const blankProgram = DemoProgram(name: 'Blank Program', source: '');

  static const exchangeAndAddSource = '''
MOV AX,12CDH
MOV BX,2121H
XCHG AX,BX
ADD AX,BX
RET
''';

  static const exchangeAndAdd = DemoProgram(
    name: 'XCHG and ADD',
    source: exchangeAndAddSource,
  );

  static const logicOperationsSource = '''
MOV AL,0FH
MOV BL,03H
AND AL,BL
OR AL,01H
XOR AL,05H
RET
''';

  static const logicOperations = DemoProgram(
    name: 'Logic Operations',
    source: logicOperationsSource,
  );

  static const rotateExampleSource = '''
MOV AL,08H
ROL AL,1
ROR AL,1
RET
''';

  static const rotateExample = DemoProgram(
    name: 'Rotate Example',
    source: rotateExampleSource,
  );

  static const multiplyDivideSource = '''
MOV AL,03H
MOV BL,03H
MUL BL
DIV BL
RET
''';

  static const multiplyDivide = DemoProgram(
    name: 'MUL and DIV',
    source: multiplyDivideSource,
  );

  static const all = [
    blankProgram,
    exchangeAndAdd,
    logicOperations,
    rotateExample,
    multiplyDivide,
  ];
}
