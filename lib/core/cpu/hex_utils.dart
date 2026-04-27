class HexUtils {
  const HexUtils._();

  static const registers16 = {'AX', 'BX', 'CX', 'DX'};
  static const registers8 = {'AH', 'AL', 'BH', 'BL', 'CH', 'CL', 'DH', 'DL'};

  static bool isRegister(String value) {
    final normalized = value.toUpperCase();
    return registers16.contains(normalized) || registers8.contains(normalized);
  }

  static bool isImmediate(String value) => parseImmediate(value) != null;

  static int? parseImmediate(String value) {
    final token = value.trim().toUpperCase();
    if (token.isEmpty) {
      return null;
    }

    if (token.endsWith('H')) {
      final hex = token.substring(0, token.length - 1);
      if (hex.isEmpty || !RegExp(r'^[0-9A-F]+$').hasMatch(hex)) {
        return null;
      }
      return int.parse(hex, radix: 16);
    }

    return int.tryParse(token);
  }

  static int maskForRegister(String registerName) {
    return registers8.contains(registerName.toUpperCase()) ? 0xFF : 0xFFFF;
  }

  static int normalizeForRegister(String registerName, int value) {
    return value & maskForRegister(registerName);
  }

  static String formatRegisterValue(String registerName, int value) {
    final isByte = registers8.contains(registerName.toUpperCase());
    final width = isByte ? 2 : 4;
    final normalized = value & (isByte ? 0xFF : 0xFFFF);
    return '${normalized.toRadixString(16).toUpperCase().padLeft(width, '0')}H';
  }

  static String formatWord(int value) {
    return '${(value & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0')}H';
  }
}
