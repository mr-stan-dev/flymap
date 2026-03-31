import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flymap/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfflineArticleHtmlView extends StatefulWidget {
  const OfflineArticleHtmlView({
    required this.htmlContent,
    required this.articleTitle,
    super.key,
  });

  final String htmlContent;
  final String articleTitle;

  @override
  State<OfflineArticleHtmlView> createState() => _OfflineArticleHtmlViewState();
}

class _OfflineArticleHtmlViewState extends State<OfflineArticleHtmlView> {
  final _logger = const Logger('OfflineArticleHtmlView');

  late final WebViewController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      );
    _initialization = _loadHtml();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return WebViewWidget(
          controller: _controller,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        );
      },
    );
  }

  Future<void> _loadHtml() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final resolved = _resolveLocalImageSources(
      html: widget.htmlContent,
      docsDirPath: docsDir.path,
    );
    final baseUrl = Uri.directory(docsDir.path).toString();

    _logger.log(
      'Loading HTML for "${widget.articleTitle}" '
      '(rewritten local images: ${resolved.localImagePaths.length})',
    );

    for (final relativePath in resolved.localImagePaths.take(5)) {
      final filePath = p.join(docsDir.path, relativePath);
      final exists = await File(filePath).exists();
      _logger.log(
        'Image file check: $relativePath exists=$exists path=$filePath',
      );
    }

    await _controller.loadHtmlString(resolved.html, baseUrl: baseUrl);
  }

  _ResolvedHtml _resolveLocalImageSources({
    required String html,
    required String docsDirPath,
  }) {
    final localImagePaths = <String>[];
    final srcPattern = RegExp(
      'src=(["\\\'])([^"\\\']+)\\1',
      caseSensitive: false,
    );

    final rewrittenHtml = html.replaceAllMapped(srcPattern, (match) {
      final quote = match.group(1)!;
      final rawSrc = (match.group(2) ?? '').trim();
      if (rawSrc.isEmpty) return match.group(0)!;

      if (rawSrc.startsWith('http:') ||
          rawSrc.startsWith('https:') ||
          rawSrc.startsWith('file:') ||
          rawSrc.startsWith('data:') ||
          rawSrc.startsWith('blob:') ||
          rawSrc.startsWith('about:')) {
        return match.group(0)!;
      }

      localImagePaths.add(rawSrc);
      final absoluteUri = Uri.file(p.join(docsDirPath, rawSrc)).toString();
      return 'src=$quote$absoluteUri$quote';
    });

    return _ResolvedHtml(html: rewrittenHtml, localImagePaths: localImagePaths);
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'about' ||
        scheme == 'data' ||
        scheme == 'file' ||
        scheme == 'blob') {
      return NavigationDecision.navigate;
    }

    _openExternal(uri);
    return NavigationDecision.prevent;
  }

  Future<void> _openExternal(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ResolvedHtml {
  const _ResolvedHtml({required this.html, required this.localImagePaths});

  final String html;
  final List<String> localImagePaths;
}
