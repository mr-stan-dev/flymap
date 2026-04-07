class WikiTextUtils {
  WikiTextUtils._();

  static final RegExp _sectionHeadingRegExp = RegExp(
    r'^\s*={2,}\s*(.+?)\s*={2,}\s*$',
  );

  /// Converts MediaWiki heading markers like `== History ==` to plain text.
  static String stripSectionMarkers(String input) {
    if (input.isEmpty) return input;
    final normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final cleaned = lines.map((line) {
      final match = _sectionHeadingRegExp.firstMatch(line);
      if (match == null) return line;
      return (match.group(1) ?? '').trim();
    });
    return cleaned.join('\n');
  }

  /// Lightweight heuristic for plaintext section headings.
  ///
  /// Works for blocks like `History`, `Geography`, `Climate`, etc.
  static bool isLikelySectionHeading(String block) {
    final line = block.trim();
    if (line.isEmpty || line.contains('\n')) return false;
    if (line.length < 3 || line.length > 64) return false;
    if (line.endsWith('.') ||
        line.endsWith('!') ||
        line.endsWith('?') ||
        line.endsWith(':') ||
        line.endsWith(',')) {
      return false;
    }

    final words = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words < 1 || words > 7) return false;

    // Avoid styling numeric-only lines as headings.
    if (RegExp(r'^\d+$').hasMatch(line)) return false;

    return true;
  }
}
