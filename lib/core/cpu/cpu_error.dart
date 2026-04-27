class CpuException implements Exception {
  const CpuException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CpuParseException extends CpuException {
  const CpuParseException(super.message, {this.lineNumber, this.hint});

  final int? lineNumber;
  final String? hint;
}

class CpuExecutionException extends CpuException {
  const CpuExecutionException(super.message);
}
