/// Native emoji (yellow sun, real clouds) for a Flymap condition code,
/// falling back to total cloud cover when the symbol is absent. Shared by
/// the weather step's airport cards and the share renderer.
String weatherSymbolEmoji(String? symbolCode, double? cloudCover) {
  final code = symbolCode ?? '';
  if (code.contains('thunder')) return '\u26c8\ufe0f';
  if (code.contains('snow') || code.contains('sleet')) {
    return '\ud83c\udf28\ufe0f';
  }
  if (code.contains('rain')) return '\ud83c\udf27\ufe0f';
  if (code.contains('fog')) return '\ud83c\udf2b\ufe0f';
  // MET appends _day / _night / _polartwilight to the clear, fair and
  // partly-cloudy symbols. Check night before the shared family prefix so a
  // clear 23:00 forecast cannot render a daytime sun.
  if (code.endsWith('_night')) {
    if (code.startsWith('clearsky') || code.startsWith('fair')) {
      return '\ud83c\udf19';
    }
    if (code.startsWith('partlycloudy')) return '\u2601\ufe0f';
  }
  if (code.startsWith('clearsky')) return '\u2600\ufe0f';
  if (code.startsWith('fair')) return '\ud83c\udf24\ufe0f';
  if (code.startsWith('partlycloudy')) return '\u26c5';
  if (code.startsWith('cloudy')) return '\u2601\ufe0f';
  // No symbol (6h-block entries sometimes omit it): fall back to cover.
  final cover = cloudCover ?? 50;
  if (cover < 25) return '\u2600\ufe0f';
  if (cover < 70) return '\u26c5';
  return '\u2601\ufe0f';
}
