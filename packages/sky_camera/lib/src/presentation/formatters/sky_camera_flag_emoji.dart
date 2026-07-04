String skyCameraFlagEmoji(String? countryCode) {
  final normalized = countryCode?.trim().toUpperCase() ?? '';
  if (normalized.length != 2) return '';
  final first = normalized.codeUnitAt(0);
  final second = normalized.codeUnitAt(1);
  bool isAsciiLetter(int code) => code >= 65 && code <= 90;
  if (!isAsciiLetter(first) || !isAsciiLetter(second)) return '';
  return String.fromCharCodes([
    0x1F1E6 + (first - 65),
    0x1F1E6 + (second - 65),
  ]);
}
