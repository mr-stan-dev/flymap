import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/offline_article_html_view.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlContentPage extends StatelessWidget {
  const HtmlContentPage({
    required this.title,
    required this.htmlContent,
    this.sourceUrl = '',
    super.key,
  });

  final String title;
  final String htmlContent;
  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = colorScheme.surface;
    final themedHtml = _applyThemedHtml(
      html: htmlContent,
      backgroundColor: pageBackground,
      textColor: colorScheme.onSurface,
      dividerColor: colorScheme.outlineVariant,
      isDarkMode: isDarkMode,
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (sourceUrl.trim().isNotEmpty)
            IconButton(
              tooltip: context.t.flight.info.openSourcePageTooltip,
              onPressed: () => _openSource(context, sourceUrl),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ColoredBox(
          color: pageBackground,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.md,
              DsSpacing.sm,
              DsSpacing.md,
              DsSpacing.sm,
            ),
            child: OfflineArticleHtmlView(
              htmlContent: themedHtml,
              articleTitle: title,
              backgroundColor: pageBackground,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(BuildContext context, String source) async {
    final uri = Uri.tryParse(source);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.settings.couldNotOpenUrl(url: source))),
      );
    }
  }

  String _applyThemedHtml({
    required String html,
    required Color backgroundColor,
    required Color textColor,
    required Color dividerColor,
    required bool isDarkMode,
  }) {
    final bgHex = _cssHex(backgroundColor);
    final textHex = _cssHex(textColor);
    final subtleLinkColor = Color.lerp(
      textColor,
      const Color(0xFF3A8DFF),
      isDarkMode ? 0.48 : 0.70,
    )!;
    final linkHex = _cssHex(subtleLinkColor);
    final dividerHex = _cssHex(dividerColor);
    final colorSchemeCss = isDarkMode ? 'dark' : 'light';
    final styles =
        '''
<style>
  :root { color-scheme: $colorSchemeCss; }
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    background: $bgHex !important;
    color: $textHex !important;
  }
  body, body * {
    color: $textHex !important;
    background-color: transparent !important;
  }
  a, a:visited {
    color: $linkHex !important;
    text-decoration: none !important;
  }
  hr {
    border: 0 !important;
    border-top: 1px solid $dividerHex !important;
  }
</style>
''';

    var normalizedHtml = html.trim();
    if (!RegExp(r'<html[\s>]', caseSensitive: false).hasMatch(normalizedHtml)) {
      normalizedHtml = '<html><head></head><body>$normalizedHtml</body></html>';
    }
    return _injectIntoHead(normalizedHtml, styles);
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
}
