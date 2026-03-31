import 'dart:convert';
import 'dart:io';

import 'package:flymap/data/wiki/wikipedia_url_utils.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/logger.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WikipediaArticleClient {
  static const _requestTimeout = Duration(seconds: 12);
  static const _userAgent = 'Flymap/0.3 (offline-flight-map-app)';
  static const _minRequestInterval = Duration(milliseconds: 180);
  static const _downloadImages = false;

  static const maxImageBytesPerFile = 1048576; // 1 MB

  final _logger = const Logger('WikipediaArticleClient');
  DateTime? _lastRequestStartedAt;

  static const _blockedTags = <String>{
    'script',
    'style',
    'noscript',
    'iframe',
    'object',
    'embed',
    'form',
    'input',
    'button',
    'textarea',
    'select',
    'svg',
    'math',
  };

  static const _allowedTags = <String>{
    'p',
    'br',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'code',
    'b',
    'strong',
    'i',
    'em',
    'u',
    'a',
    'hr',
    'div',
    'span',
  };

  Future<FlightArticle?> downloadArticle({
    required String sourceUrl,
    required String bundleId,
  }) async {
    final ref = WikipediaUrlUtils.parseArticle(sourceUrl);
    if (ref == null) return null;

    final summaryData = await _fetchSummary(ref);
    if (summaryData == null) return null;

    final source = _extractSourceUrl(summaryData) ?? ref.canonicalUrl;
    final summary = (summaryData['extract'] ?? '').toString().trim();
    final title = (summaryData['title'] ?? ref.title).toString().trim();
    final resolvedTitle = title.isNotEmpty ? title : ref.title;

    final articleDirectoryRelativePath = _articleRelativeDir(
      bundleId: bundleId,
      languageCode: ref.languageCode,
      title: resolvedTitle,
      sourceUrl: source,
    );

    try {
      _StoredImage? leadImage;
      if (_downloadImages) {
        final leadImageUrl = _extractLeadImageUrl(summaryData);
        leadImage = await _downloadImageWithSizeFallback(
          imageUrl: leadImageUrl,
          articleDirectoryRelativePath: articleDirectoryRelativePath,
          filePrefix: 'lead',
        );
      }

      final rawHtml = await _fetchParsedHtml(ref);
      final htmlResult = rawHtml == null
          ? null
          : await _sanitizeAndStoreHtml(
              rawHtml: rawHtml,
              languageCode: ref.languageCode,
              articleDirectoryRelativePath: articleDirectoryRelativePath,
            );

      final plainText = htmlResult?.plainText.trim().isNotEmpty == true
          ? htmlResult!.plainText.trim()
          : await _fetchPlainTextContent(ref) ?? '';
      final contentHtml = htmlResult?.html.trim() ?? '';

      if (plainText.isEmpty && contentHtml.isEmpty) {
        await _deleteRelativeDir(articleDirectoryRelativePath);
        return null;
      }

      final inlinePaths =
          htmlResult?.inlineImageRelativePaths ?? const <String>[];
      final textBytes = utf8.encode(summary + plainText + contentHtml).length;
      final imageBytes =
          (leadImage?.sizeBytes ?? 0) + (htmlResult?.imagesBytes ?? 0);
      final totalBytes = textBytes + imageBytes;

      _logger.log(
        'Article saved: title="$resolvedTitle" '
        'leadImage=${leadImage?.relativePath ?? 'none'} '
        'inlineImages=${inlinePaths.length} sizeBytes=$totalBytes',
      );

      return FlightArticle(
        sourceUrl: source,
        title: resolvedTitle,
        summary: summary,
        contentPlainText: plainText,
        contentHtml: contentHtml,
        languageCode: ref.languageCode,
        leadImageRelativePath: leadImage?.relativePath ?? '',
        inlineImageRelativePaths: inlinePaths,
        attributionText: 'Source: Wikipedia contributors',
        licenseText:
            'Text is available under CC BY-SA 4.0; additional terms may apply.',
        downloadedAt: DateTime.now(),
        sizeBytes: totalBytes,
      );
    } catch (_) {
      await _deleteRelativeDir(articleDirectoryRelativePath);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchSummary(WikipediaArticleRef ref) async {
    final uri = Uri.https(
      '${ref.languageCode}.wikipedia.org',
      '/api/rest_v1/page/summary/${ref.encodedTitle}',
    );
    await _throttleRequests();
    final response = await http
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(_requestTimeout);
    if (response.statusCode != 200) return null;
    final dynamic body = jsonDecode(response.body);
    if (body is! Map) return null;
    return body.cast<String, dynamic>();
  }

  Future<String?> _fetchParsedHtml(WikipediaArticleRef ref) async {
    final uri = Uri.https('${ref.languageCode}.wikipedia.org', '/w/api.php', {
      'action': 'parse',
      'page': ref.title,
      'prop': 'text',
      'redirects': '1',
      'disableeditsection': '1',
      'disabletoc': '1',
      'format': 'json',
      'formatversion': '2',
    });

    await _throttleRequests();
    final response = await http
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(_requestTimeout);

    if (response.statusCode != 200) return null;

    final dynamic body = jsonDecode(response.body);
    if (body is! Map) return null;
    final parse = body['parse'];
    if (parse is! Map) return null;

    final rawHtml = (parse['text'] ?? '').toString();
    return rawHtml.trim().isEmpty ? null : rawHtml;
  }

  Future<String?> _fetchPlainTextContent(WikipediaArticleRef ref) async {
    final uri = Uri.https('${ref.languageCode}.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'prop': 'extracts',
      'explaintext': '1',
      'redirects': '1',
      'titles': ref.title,
      'format': 'json',
      'formatversion': '2',
    });

    await _throttleRequests();
    final response = await http
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(_requestTimeout);
    if (response.statusCode != 200) return null;
    final dynamic body = jsonDecode(response.body);
    if (body is! Map) return null;

    final query = body['query'];
    if (query is! Map) return null;
    final pages = query['pages'];
    if (pages is! List) return null;

    for (final page in pages.whereType<Map>()) {
      if ((page['missing'] ?? false) == true) continue;
      final extract = (page['extract'] ?? '').toString();
      if (extract.trim().isNotEmpty) {
        return extract;
      }
    }
    return null;
  }

  Future<_SanitizedHtmlResult> _sanitizeAndStoreHtml({
    required String rawHtml,
    required String languageCode,
    required String articleDirectoryRelativePath,
  }) async {
    final fragment = html_parser.parseFragment(rawHtml);
    _removeNoisyWikipediaBlocks(fragment);

    final contentRoot = dom.Element.tag('div')
      ..classes.add('offline-article-content')
      ..nodes.addAll(fragment.nodes);

    _sanitizeTree(contentRoot, languageCode: languageCode);

    final inlineImagePaths = <String>[];
    var inlineImagesBytes = 0;
    final imageNodes = List<dom.Element>.from(
      contentRoot.querySelectorAll('img'),
    );
    _logger.log(
      'Sanitizing article HTML, found image tags: ${imageNodes.length}',
    );

    if (!_downloadImages) {
      for (final node in imageNodes) {
        node.remove();
      }
      final htmlBody = contentRoot.innerHtml.trim();
      final plainText = contentRoot.text.trim();
      if (htmlBody.isEmpty && plainText.isEmpty) {
        return const _SanitizedHtmlResult(
          html: '',
          plainText: '',
          inlineImageRelativePaths: <String>[],
          imagesBytes: 0,
        );
      }
      return _SanitizedHtmlResult(
        html: _wrapAsOfflineHtmlDocument(htmlBody),
        plainText: plainText,
        inlineImageRelativePaths: const <String>[],
        imagesBytes: 0,
      );
    }

    var imageIndex = 0;
    for (final imageNode in imageNodes) {
      imageIndex++;

      final rawSrc = (imageNode.attributes['src'] ?? '').trim();
      final normalizedSrc = _normalizeImageUrl(rawSrc, languageCode);
      if (normalizedSrc == null) {
        imageNode.remove();
        continue;
      }

      final downloadedImage = await _downloadImageWithSizeFallback(
        imageUrl: normalizedSrc,
        articleDirectoryRelativePath: articleDirectoryRelativePath,
        filePrefix: 'img_$imageIndex',
      );

      if (downloadedImage == null ||
          downloadedImage.sizeBytes <= 0 ||
          downloadedImage.sizeBytes > maxImageBytesPerFile) {
        if (downloadedImage != null) {
          await _deleteRelativeFile(downloadedImage.relativePath);
        }
        imageNode.remove();
        continue;
      }

      imageNode.attributes
        ..remove('srcset')
        ..remove('sizes')
        ..['src'] = downloadedImage.relativePath
        ..['loading'] = 'lazy';

      inlineImagePaths.add(downloadedImage.relativePath);
      inlineImagesBytes += downloadedImage.sizeBytes;
    }

    _logger.log(
      'Sanitized HTML images kept=${inlineImagePaths.length} bytes=$inlineImagesBytes',
    );

    final htmlBody = contentRoot.innerHtml.trim();
    final plainText = contentRoot.text.trim();
    if (htmlBody.isEmpty && plainText.isEmpty) {
      return const _SanitizedHtmlResult(
        html: '',
        plainText: '',
        inlineImageRelativePaths: <String>[],
        imagesBytes: 0,
      );
    }

    return _SanitizedHtmlResult(
      html: _wrapAsOfflineHtmlDocument(htmlBody),
      plainText: plainText,
      inlineImageRelativePaths: inlineImagePaths,
      imagesBytes: inlineImagesBytes,
    );
  }

  void _removeNoisyWikipediaBlocks(dom.Node root) {
    if (root is! dom.Element && root is! dom.DocumentFragment) return;

    final removableSelectors = <String>[
      '.infobox',
      '.vertical-navbox',
      '.navbox',
      '.metadata',
      '.mw-editsection',
      '.mw-references-wrap',
      '.reference',
      '.thumbcaption .magnify',
      '.hatnote',
      'table',
      'style',
      'script',
      'noscript',
    ];

    for (final selector in removableSelectors) {
      final nodes = root is dom.Element
          ? root.querySelectorAll(selector)
          : (root as dom.DocumentFragment).querySelectorAll(selector);
      for (final node in nodes) {
        node.remove();
      }
    }
  }

  void _sanitizeTree(dom.Node node, {required String languageCode}) {
    if (node is! dom.Element && node is! dom.DocumentFragment) return;

    final children = node is dom.Element
        ? List<dom.Node>.from(node.nodes)
        : List<dom.Node>.from((node as dom.DocumentFragment).nodes);
    for (final child in children) {
      if (child is dom.Comment) {
        child.remove();
        continue;
      }

      if (child is dom.Element) {
        final tag = (child.localName ?? '').toLowerCase();

        if (_blockedTags.contains(tag)) {
          child.remove();
          continue;
        }

        _sanitizeTree(child, languageCode: languageCode);

        if (!_allowedTags.contains(tag)) {
          _unwrapElement(child);
          continue;
        }

        _sanitizeAttributes(child, languageCode: languageCode);
      }
    }
  }

  void _sanitizeAttributes(
    dom.Element element, {
    required String languageCode,
  }) {
    final tag = (element.localName ?? '').toLowerCase();
    final allowed = <String>{};

    switch (tag) {
      case 'a':
        allowed.addAll(const {'href', 'title'});
        break;
      default:
        break;
    }

    final attributes = Map<String, String>.from(element.attributes);
    for (final key in attributes.keys) {
      if (!allowed.contains(key.toLowerCase())) {
        element.attributes.remove(key);
      }
    }

    if (tag == 'a') {
      final href = (element.attributes['href'] ?? '').trim();
      final normalizedHref = _normalizeAnchorHref(href, languageCode);
      if (normalizedHref == null) {
        element.attributes.remove('href');
      } else {
        element.attributes['href'] = normalizedHref;
      }
    }
  }

  void _unwrapElement(dom.Element element) {
    final parent = element.parent;
    if (parent == null) {
      element.remove();
      return;
    }

    final index = parent.nodes.indexOf(element);
    final children = List<dom.Node>.from(element.nodes);
    for (final child in children) {
      child.remove();
    }
    element.remove();
    parent.nodes.insertAll(index, children);
  }

  String? _normalizeAnchorHref(String href, String languageCode) {
    if (href.isEmpty || href.startsWith('#')) return null;
    if (href.startsWith('//')) return 'https:$href';
    if (href.startsWith('/')) return 'https://$languageCode.wikipedia.org$href';

    final uri = Uri.tryParse(href);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }
    return uri.toString();
  }

  String? _normalizeImageUrl(String src, String languageCode) {
    if (src.isEmpty || src.startsWith('data:')) return null;

    final normalized = src.startsWith('//')
        ? 'https:$src'
        : src.startsWith('/')
        ? 'https://$languageCode.wikipedia.org$src'
        : src;

    final uri = Uri.tryParse(normalized);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.endsWith('wikimedia.org') && !host.endsWith('wikipedia.org')) {
      return null;
    }

    final extension = p.extension(uri.path).toLowerCase();
    if (extension == '.svg' || extension == '.gif') return null;

    return uri.toString();
  }

  String _toPreferredImageUrl(String imageUrl, {required int width}) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return imageUrl;

    final host = uri.host.toLowerCase();
    if (!host.endsWith('wikimedia.org')) return imageUrl;

    final segments = uri.pathSegments;
    if (segments.length < 4) return imageUrl;
    if (segments.contains('thumb')) return imageUrl;

    final extension = p.extension(uri.path).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)) {
      return imageUrl;
    }

    final fileName = segments.last;
    final withThumb = segments.contains('thumb')
        ? _replaceThumbWidth(segments: segments, width: width)
        : [
            ...segments.take(2),
            'thumb',
            ...segments.skip(2),
            '${width}px-$fileName',
          ];

    return uri.replace(pathSegments: withThumb).toString();
  }

  List<String> _replaceThumbWidth({
    required List<String> segments,
    required int width,
  }) {
    if (segments.isEmpty) return segments;
    final out = List<String>.from(segments);
    final last = out.last;
    final replaced = last.replaceFirst(RegExp(r'^\d+px-'), '${width}px-');
    out[out.length - 1] = replaced == last && !last.startsWith('${width}px-')
        ? '${width}px-$last'
        : replaced;
    return out;
  }

  Future<_StoredImage?> _downloadImageWithSizeFallback({
    required String? imageUrl,
    required String articleDirectoryRelativePath,
    required String filePrefix,
  }) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      _logger.log('Skip image download: empty image URL for $filePrefix');
      return null;
    }

    final candidates = <String>[
      imageUrl,
      _toPreferredImageUrl(imageUrl, width: 960),
      _toPreferredImageUrl(imageUrl, width: 640),
      _toPreferredImageUrl(imageUrl, width: 480),
    ].where((candidate) => candidate.trim().isNotEmpty).toSet().toList();

    for (final candidate in candidates) {
      final downloaded = await _downloadImage(
        imageUrl: candidate,
        articleDirectoryRelativePath: articleDirectoryRelativePath,
        filePrefix: filePrefix,
      );
      if (downloaded == null) continue;
      if (downloaded.sizeBytes <= maxImageBytesPerFile) {
        _logger.log(
          'Downloaded image $filePrefix from $candidate '
          'bytes=${downloaded.sizeBytes}',
        );
        return downloaded;
      }
      _logger.log(
        'Dropped oversized image $filePrefix from $candidate '
        'bytes=${downloaded.sizeBytes} cap=$maxImageBytesPerFile',
      );
      await _deleteRelativeFile(downloaded.relativePath);
    }

    _logger.log('Failed to download image for $filePrefix from all candidates');
    return null;
  }

  Future<_StoredImage?> _downloadImage({
    required String? imageUrl,
    required String articleDirectoryRelativePath,
    required String filePrefix,
  }) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return null;

    await _throttleRequests();
    final response = await http
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      _logger.log(
        'Image HTTP ${response.statusCode} for $filePrefix from $imageUrl',
      );
      return null;
    }
    if (response.bodyBytes.isEmpty) {
      _logger.log('Image body empty for $filePrefix from $imageUrl');
      return null;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final absoluteDir = p.join(docsDir.path, articleDirectoryRelativePath);
    await Directory(absoluteDir).create(recursive: true);

    final extension = _inferImageExtension(uri.path);
    var fileName = '$filePrefix$extension';
    var filePath = p.join(absoluteDir, fileName);

    var suffix = 1;
    while (await File(filePath).exists()) {
      fileName = '${filePrefix}_$suffix$extension';
      filePath = p.join(absoluteDir, fileName);
      suffix++;
    }

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes, flush: true);

    return _StoredImage(
      relativePath: p.join(articleDirectoryRelativePath, fileName),
      sizeBytes: response.bodyBytes.length,
    );
  }

  Future<void> _deleteRelativeFile(String relativePath) async {
    if (relativePath.trim().isEmpty) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(docsDir.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _deleteRelativeDir(String relativePath) async {
    if (relativePath.trim().isEmpty) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, relativePath));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  String? _extractLeadImageUrl(Map<String, dynamic> summary) {
    final original = summary['originalimage'];
    if (original is Map && (original['source'] ?? '').toString().isNotEmpty) {
      return original['source'].toString();
    }
    final thumb = summary['thumbnail'];
    if (thumb is Map && (thumb['source'] ?? '').toString().isNotEmpty) {
      return thumb['source'].toString();
    }
    return null;
  }

  String? _extractSourceUrl(Map<String, dynamic> summary) {
    final contentUrls = summary['content_urls'];
    if (contentUrls is! Map) return null;
    final desktop = contentUrls['desktop'];
    if (desktop is! Map) return null;
    final page = (desktop['page'] ?? '').toString().trim();
    return page.isEmpty ? null : page;
  }

  String _articleRelativeDir({
    required String bundleId,
    required String languageCode,
    required String title,
    required String sourceUrl,
  }) {
    final safeBundleId = _sanitizePathPart(bundleId);
    final articleSlug = '${_slug(languageCode)}_${_slug(title)}';
    return p.join(
      'article_media',
      safeBundleId,
      '${articleSlug}_${_shortHash(sourceUrl)}',
    );
  }

  String _sanitizePathPart(String input) {
    final compact = input.trim().replaceAll(RegExp(r'\s+'), '_');
    final cleaned = compact.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return cleaned.isEmpty ? 'bundle' : cleaned;
  }

  String _slug(String input) {
    final compact = input.trim().replaceAll(RegExp(r'\s+'), '_');
    final cleaned = compact.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final collapsed = cleaned.replaceAll(RegExp(r'_+'), '_');
    if (collapsed.isEmpty) return 'article';
    return collapsed.length > 60 ? collapsed.substring(0, 60) : collapsed;
  }

  String _shortHash(String input) {
    var hash = 0;
    for (final byte in utf8.encode(input)) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _inferImageExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
        return ext;
      default:
        return '.jpg';
    }
  }

  Future<void> _throttleRequests() async {
    final last = _lastRequestStartedAt;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestStartedAt = DateTime.now();
  }

  String _wrapAsOfflineHtmlDocument(String contentBody) {
    return '''<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  body {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.55;
    color: #1f2937;
    background: #ffffff;
  }
  .offline-article-content {
    margin: 0;
    padding: 0;
  }
  p, li, blockquote, pre {
    font-size: 16px;
  }
  h2, h3, h4 {
    margin: 20px 0 10px;
    line-height: 1.3;
  }
  p {
    margin: 0 0 12px;
  }
  a {
    color: #0f4c81;
    text-decoration: none;
  }
</style>
</head>
<body>
$contentBody
</body>
</html>
''';
  }
}

class _StoredImage {
  const _StoredImage({required this.relativePath, required this.sizeBytes});

  final String relativePath;
  final int sizeBytes;
}

class _SanitizedHtmlResult {
  const _SanitizedHtmlResult({
    required this.html,
    required this.plainText,
    required this.inlineImageRelativePaths,
    required this.imagesBytes,
  });

  final String html;
  final String plainText;
  final List<String> inlineImageRelativePaths;
  final int imagesBytes;
}
