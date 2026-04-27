import 'cpu_error.dart';

class Memory {
  Memory({int size = 32}) : _cells = List<int>.filled(size, 0) {
    if (size <= 0) {
      throw const CpuExecutionException(
        'Memory size must be greater than zero.',
      );
    }
  }

  final List<int> _cells;

  int get size => _cells.length;

  List<int> snapshot() => List.unmodifiable(_cells);

  int read(int address) {
    _ensureAddress(address);
    return _cells[address];
  }

  void write(int address, int value) {
    _ensureAddress(address);
    _cells[address] = value;
  }

  void reset() {
    for (var index = 0; index < _cells.length; index++) {
      _cells[index] = 0;
    }
  }

  void _ensureAddress(int address) {
    if (address < 0 || address >= _cells.length) {
      throw CpuExecutionException(
        'Memory address $address is out of range. Valid addresses are 0-${_cells.length - 1}.',
      );
    }
  }
}
