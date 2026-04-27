class ParsedInstruction {
  const ParsedInstruction({
    required this.mnemonic,
    required this.operands,
    required this.sourceLineNumber,
    required this.rawText,
  });

  final String mnemonic;
  final List<String> operands;
  final int sourceLineNumber;
  final String rawText;

  String get normalizedText {
    if (operands.isEmpty) {
      return mnemonic;
    }
    return '$mnemonic ${operands.join(',')}';
  }
}
