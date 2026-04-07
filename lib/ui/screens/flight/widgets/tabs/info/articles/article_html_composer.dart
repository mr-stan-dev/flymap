import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';

String composeScrollableHtml({
  required FlightArticle article,
  required Color backgroundColor,
  required Color textColor,
  required Color mutedTextColor,
  required Color dividerColor,
  required bool isDarkMode,
}) {
  final summary = article.summary.trim();
  final bgHex = _cssHex(backgroundColor);
  final textHex = _cssHex(textColor);
  final subtleLinkColor = Color.lerp(
    textColor,
    const Color(0xFF3A8DFF),
    isDarkMode ? 0.48 : 0.70,
  )!;
  final linkHex = _cssHex(subtleLinkColor);
  final mutedHex = _cssHex(mutedTextColor);
  final dividerHex = _cssHex(dividerColor);
  final colorScheme = isDarkMode ? 'dark' : 'light';

  final injectedStyles =
      '''
<style>
  :root {
    color-scheme: $colorScheme;
  }
  html {
    margin: 0 !important;
    padding: 0 !important;
    background: $bgHex !important;
  }
  body {
    margin: 0 !important;
    padding: 0 !important;
    background: $bgHex !important;
    color: $textHex !important;
  }
  .offline-shell {
    min-height: 100vh;
    box-sizing: border-box;
    padding: 12px 14px 20px;
    background: $bgHex !important;
    color: $textHex !important;
  }
  .offline-shell,
  .offline-shell * {
    background-color: transparent !important;
    color: $textHex !important;
  }
  .offline-shell a,
  .offline-shell a:visited {
    color: $linkHex !important;
    text-decoration: none !important;
  }
  .offline-shell hr {
    border: 0 !important;
    border-top: 1px solid $dividerHex !important;
    margin: 16px 0 !important;
  }
  .offline-summary,
  .offline-meta {
    color: $mutedHex !important;
  }
  .offline-meta {
    margin: 0 0 6px;
    font-size: 13px;
  }
</style>
''';

  final headerBlocks = <String>[
    if (summary.isNotEmpty)
      '<p class="offline-summary">${_escapeHtml(summary)}</p>',
  ].join('\n');

  final footerBlock =
      '''
<hr />
<p class="offline-meta">${_escapeHtml(article.attributionText)}</p>
<p class="offline-meta">${_escapeHtml(article.licenseText)}</p>
<p class="offline-meta"><a href="${_escapeAttr(article.sourceUrl)}">Open source page</a> • ${_escapeHtml(article.languageCode.toUpperCase())}</p>
''';

  var html = article.contentHtml;
  // V2 simplification: keep offline articles text-first and ignore all images.
  html = html.replaceAll(RegExp(r'<img\b[^>]*>', caseSensitive: false), '');
  html = _injectIntoHead(html, injectedStyles);
  html = html.replaceFirstMapped(
    RegExp(r'<body[^>]*>', caseSensitive: false),
    (match) =>
        '${match.group(0)}\n<div class="offline-shell">\n$headerBlocks\n',
  );

  if (html.contains(RegExp(r'</body>', caseSensitive: false))) {
    html = html.replaceFirst(
      RegExp(r'</body>', caseSensitive: false),
      '$footerBlock\n</div>\n</body>',
    );
  } else {
    html = '$html\n$footerBlock\n</div>';
  }

  return html;
}

String _injectIntoHead(String html, String styles) {
  final headClose = RegExp(r'</head>', caseSensitive: false);
  if (headClose.hasMatch(html)) {
    return html.replaceFirst(headClose, '$styles\n</head>');
  }

  final htmlOpen = RegExp(r'<html[^>]*>', caseSensitive: false);
  if (htmlOpen.hasMatch(html)) {
    return html.replaceFirstMapped(
      htmlOpen,
      (match) => '${match.group(0)}\n<head>\n$styles\n</head>',
    );
  }

  return '<head>\n$styles\n</head>\n$html';
}

String _cssHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _escapeAttr(String value) => _escapeHtml(value);
