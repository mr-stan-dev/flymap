import 'package:flymap/entity/flight_article.dart';

String composeScrollableHtml(FlightArticle article) {
  final summary = article.summary.trim();

  const injectedStyles = '''
<style>
  body {
    margin: 0 !important;
    padding: 0 !important;
  }
  .offline-shell {
    padding: 12px 14px 20px;
  }
  .offline-summary {
    margin: 0 0 12px;
    color: #4b5563;
  }
  .offline-meta {
    margin: 0 0 6px;
    color: #6b7280;
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
  html = html.replaceFirst(
    RegExp(r'</head>', caseSensitive: false),
    '$injectedStyles\n</head>',
  );
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

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _escapeAttr(String value) => _escapeHtml(value);
