import '../cpu/cpu_error.dart';
import '../cpu/hex_utils.dart';
import 'parsed_instruction.dart';

class ProgramParser {
  ProgramParser({Iterable<String>? registerNames})
    : _registerNames =
          registerNames?.map((name) => name.toUpperCase()).toSet() ??
          {...HexUtils.registers16, ...HexUtils.registers8};

  final Set<String> _registerNames;

  static const Map<String, int> _operandCounts = {
    'MOV': 2,
    'XCHG': 2,
    'ADD': 2,
    'SUB': 2,
    'INC': 1,
    'DEC': 1,
    'MUL': 1,
    'DIV': 1,
    'AND': 2,
    'OR': 2,
    'XOR': 2,
    'ROL': 2,
    'ROR': 2,
    'RET': 0,
  };

  List<ParsedInstruction> parse(String source) {
    final instructions = <ParsedInstruction>[];
    final lines = source.split(RegExp(r'\r?\n'));

    for (var index = 0; index < lines.length; index++) {
      final sourceLineNumber = index + 1;
      final cleaned = _stripComment(lines[index]).trim();
      if (cleaned.isEmpty) {
        continue;
      }

      final normalized = cleaned.replaceAll(',', ' ');
      final parts = normalized.split(RegExp(r'\s+'));
      final mnemonic = parts.first.toUpperCase();
      final operands = parts
          .skip(1)
          .map((part) => part.toUpperCase())
          .toList(growable: false);

      _validateInstruction(mnemonic, operands, sourceLineNumber);

      instructions.add(
        ParsedInstruction(
          mnemonic: mnemonic,
          operands: operands,
          sourceLineNumber: sourceLineNumber,
          rawText: cleaned,
        ),
      );
    }

    if (instructions.isEmpty) {
      throw const CpuParseException(
        'Program is empty. Add at least one instruction.',
        hint: 'Try: MOV AX,12CDH',
      );
    }

    return instructions;
  }

  String _stripComment(String line) {
    final semicolonIndex = line.indexOf(';');
    final hashIndex = line.indexOf('#');
    final indexes = [
      semicolonIndex,
      hashIndex,
    ].where((index) => index >= 0).toList();
    if (indexes.isEmpty) {
      return line;
    }
    indexes.sort();
    return line.substring(0, indexes.first);
  }

  void _validateInstruction(
    String mnemonic,
    List<String> operands,
    int lineNumber,
  ) {
    final expectedCount = _operandCounts[mnemonic];
    if (expectedCount == null) {
      throw CpuParseException(
        'Line $lineNumber: "$mnemonic" is not supported. Use MOV, XCHG, ADD, SUB, INC, DEC, MUL, DIV, AND, OR, XOR, ROL, ROR, or RET.',
        lineNumber: lineNumber,
        hint: 'Use one of the supported 8086 simulator instructions.',
      );
    }

    if (operands.length != expectedCount) {
      throw CpuParseException(
        'Line $lineNumber: $mnemonic expects $expectedCount operand${expectedCount == 1 ? '' : 's'}. Example: ${_exampleFor(mnemonic)}',
        lineNumber: lineNumber,
        hint: _exampleFor(mnemonic),
      );
    }

    switch (mnemonic) {
      case 'MOV':
        _expectRegister(operands[0], lineNumber, mnemonic);
        _expectRegisterOrImmediate(operands[1], lineNumber, mnemonic);
        break;
      case 'XCHG':
        _expectRegister(operands[0], lineNumber, mnemonic);
        _expectRegister(operands[1], lineNumber, mnemonic);
        break;
      case 'ADD':
      case 'SUB':
      case 'AND':
      case 'OR':
      case 'XOR':
        _expectRegister(operands[0], lineNumber, mnemonic);
        _expectRegisterOrImmediate(operands[1], lineNumber, mnemonic);
        break;
      case 'INC':
      case 'DEC':
        _expectRegister(operands[0], lineNumber, mnemonic);
        break;
      case 'MUL':
      case 'DIV':
        _expectRegisterOrImmediate(operands[0], lineNumber, mnemonic);
        break;
      case 'ROL':
      case 'ROR':
        _expectRegister(operands[0], lineNumber, mnemonic);
        _expectInteger(operands[1], lineNumber, mnemonic);
        if (HexUtils.parseImmediate(operands[1]) != 1) {
          throw CpuParseException(
            'Line $lineNumber: $mnemonic currently supports rotate count 1 only.',
            lineNumber: lineNumber,
            hint: _exampleFor(mnemonic),
          );
        }
        break;
      case 'RET':
        break;
    }
  }

  void _expectRegister(String value, int lineNumber, String mnemonic) {
    if (!_registerNames.contains(value.toUpperCase())) {
      throw CpuParseException(
        'Line $lineNumber: $mnemonic expected a register, but found "$value". Use ${_registerNames.join(', ')}.',
        lineNumber: lineNumber,
        hint: _exampleFor(mnemonic),
      );
    }
  }

  void _expectInteger(String value, int lineNumber, String mnemonic) {
    if (!HexUtils.isImmediate(value)) {
      throw CpuParseException(
        'Line $lineNumber: $mnemonic expected a decimal or 8086 hex value, but found "$value".',
        lineNumber: lineNumber,
        hint: _exampleFor(mnemonic),
      );
    }
  }

  void _expectRegisterOrImmediate(
    String value,
    int lineNumber,
    String mnemonic,
  ) {
    if (_registerNames.contains(value.toUpperCase()) ||
        HexUtils.isImmediate(value)) {
      return;
    }

    throw CpuParseException(
      'Line $lineNumber: $mnemonic expected a register or immediate value, but found "$value".',
      lineNumber: lineNumber,
      hint: _exampleFor(mnemonic),
    );
  }

  String _exampleFor(String mnemonic) {
    switch (mnemonic) {
      case 'MOV':
        return 'MOV AX,12CDH';
      case 'XCHG':
        return 'XCHG AX,BX';
      case 'ADD':
        return 'ADD AX,BX';
      case 'SUB':
        return 'SUB AX,2H';
      case 'INC':
        return 'INC AX';
      case 'DEC':
        return 'DEC AX';
      case 'MUL':
        return 'MUL BL';
      case 'DIV':
        return 'DIV BL';
      case 'AND':
        return 'AND AL,BL';
      case 'OR':
        return 'OR AL,01H';
      case 'XOR':
        return 'XOR AL,05H';
      case 'ROL':
        return 'ROL AL,1';
      case 'ROR':
        return 'ROR AL,1';
      case 'RET':
        return 'RET';
      default:
        return 'MOV AX,12CDH';
    }
  }
}
