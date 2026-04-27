import 'cpu_error.dart';

class Registers {
  Registers({
    List<String> names = defaultNames,
    Map<String, int>? general,
    Map<String, String> aliases = const {},
    this.pc = 0,
    this.ir = '',
    this.programCounterName = 'PC',
  }) : _names = names.map((name) => name.toUpperCase()).toList(growable: false),
       _aliases = aliases.map(
         (key, value) => MapEntry(key.toUpperCase(), value.toUpperCase()),
       ),
       _general = {
         for (final name in names.map((name) => name.toUpperCase()))
           name: general?[name] ?? general?[name.toUpperCase()] ?? 0,
       } {
    _ensureAliasesTargetKnown();
    syncProgramCounterRegister();
  }

  static const List<String> defaultNames = [
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

  final List<String> _names;
  final Map<String, int> _general;
  final Map<String, String> _aliases;
  int pc;
  String ir;
  final String programCounterName;

  static const List<String> names = defaultNames;

  int read(String name) {
    final normalized = _resolveName(name);
    _ensureRegister(normalized);
    return _general[normalized]!;
  }

  void write(String name, int value) {
    final normalized = _resolveName(name);
    _ensureRegister(normalized);
    _general[normalized] = value;
  }

  Map<String, int> snapshot() => Map.unmodifiable(_general);

  void reset() {
    for (final name in _names) {
      _general[name] = 0;
    }
    pc = 0;
    ir = '';
    syncProgramCounterRegister();
  }

  bool supportsRegister(String name) {
    final normalized = name.toUpperCase();
    return _general.containsKey(normalized) || _aliases.containsKey(normalized);
  }

  static bool isGeneralRegister(String value) {
    return names.contains(value.toUpperCase());
  }

  void syncProgramCounterRegister() {
    final normalized = programCounterName.toUpperCase();
    if (_general.containsKey(normalized)) {
      _general[normalized] = pc;
    }
  }

  String _resolveName(String name) {
    final normalized = name.toUpperCase();
    return _aliases[normalized] ?? normalized;
  }

  void _ensureRegister(String name) {
    if (!_general.containsKey(name)) {
      throw CpuExecutionException(
        'Unknown register "$name". Use ${_names.join(', ')}.',
      );
    }
  }

  void _ensureAliasesTargetKnown() {
    for (final entry in _aliases.entries) {
      if (!_general.containsKey(entry.value)) {
        throw CpuExecutionException(
          'Register alias "${entry.key}" points to unknown register "${entry.value}".',
        );
      }
    }
  }
}
