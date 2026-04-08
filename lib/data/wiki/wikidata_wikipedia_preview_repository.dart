import 'dart:convert';
import 'dart:math';

import 'package:flymap/data/wiki/poi_preview_content_config.dart';
import 'package:flymap/data/wiki/wikimedia_api_client.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/utils/wiki_text_utils.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class WikidataWikipediaPreviewRepository implements PoiWikiPreviewRepository {
  WikidataWikipediaPreviewRepository({required WikimediaApiClient apiClient})
    : _apiClient = apiClient;

  static const _requestTimeout = Duration(seconds: 12);
  static const _maxBatchSize = 50;
  static const _minRequestInterval = Duration(milliseconds: 180);

  final Logger _logger = const Logger('WikidataWikipediaPreviewRepository');
  final WikimediaApiClient _apiClient;
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

  // ── Single-QID path (dialog taps, online mode) ───────────────────────────
  // Delegates to batchGetWikiPreviews so both dialog contexts (preview map and
  // offline map) receive identical content: the full Wikipedia lead section.

  @override
  Future<PoiWikiPreview?> getWikiPreviewByQid({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    final normalizedQid = qid.trim().toUpperCase();
    if (normalizedQid.isEmpty) return null;
    final results = await batchGetWikiPreviews(
      qids: [normalizedQid],
      preferredLanguageCode: preferredLanguageCode,
    );
    return results[normalizedQid];
  }

  // ── Batch path (download phase) ───────────────────────────────────────────

  @override
  Future<Map<String, PoiWikiPreview>> batchGetWikiPreviews({
    required List<String> qids,
    required String preferredLanguageCode,
  }) async {
    final normalizedQids = qids
        .map((q) => q.trim().toUpperCase())
        .where((q) => q.isNotEmpty)
        .toList(growable: false);

    if (normalizedQids.isEmpty) return {};

    final preferred = _normalizeLanguageCode(preferredLanguageCode);

    // Step 1: batch-resolve all QIDs to Wikipedia titles via Wikidata.
    final resolved = await _batchResolveQids(
      qids: normalizedQids,
      preferredLanguageCode: preferred,
    );
    if (resolved.isEmpty) return {};

    _logger.log(
      'Batch resolved ${resolved.length}/${normalizedQids.length} QIDs to Wikipedia titles',
    );

    final mode = PoiPreviewContentConfig.mode;
    Map<String, String> introExtracts = const {};
    Map<String, String> fullExtracts = const {};
    final htmlByQid = await _batchFetchHtml(resolvedByQid: resolved);
    _logger.log(
      'Batch fetched sanitized HTML for ${htmlByQid.length}/${resolved.length} resolved titles',
    );

    if (mode == PoiPreviewContentMode.fullText) {
      final weakHtmlQids = resolved.entries
          .where((entry) {
            final htmlPreview = htmlByQid[entry.key];
            return _isWeakSummary(htmlPreview?.plainText, entry.value.title);
          })
          .map((entry) => entry.key)
          .toList(growable: false);

      if (weakHtmlQids.isNotEmpty) {
        final weakResolved = <String, _ResolvedWikiTitle>{
          for (final qid in weakHtmlQids)
            if (resolved.containsKey(qid)) qid: resolved[qid]!,
        };
        fullExtracts = await _batchFetchExtracts(
          resolvedByQid: weakResolved,
          introOnly: false,
        );
        _logger.log(
          'Batch fetched full extracts for ${fullExtracts.length}/${weakResolved.length} weak-html entries',
        );

        final weakFullQids = weakResolved.entries
            .where(
              (entry) =>
                  _isWeakSummary(fullExtracts[entry.key], entry.value.title),
            )
            .map((entry) => entry.key)
            .toList(growable: false);

        if (weakFullQids.isNotEmpty) {
          introExtracts = await _batchFetchExtracts(
            resolvedByQid: {
              for (final qid in weakFullQids)
                if (resolved.containsKey(qid)) qid: resolved[qid]!,
            },
            introOnly: true,
          );
          _logger.log(
            'Batch fetched intro fallback extracts for ${introExtracts.length}/${weakFullQids.length} weak full-text entries',
          );
        }
      }
    } else {
      // Summary-first mode: intro first, full text only for weak intro entries.
      introExtracts = await _batchFetchExtracts(
        resolvedByQid: resolved,
        introOnly: true,
      );

      _logger.log(
        'Batch fetched intro extracts for ${introExtracts.length}/${resolved.length} resolved titles',
      );

      final weakQids = resolved.entries
          .where(
            (entry) =>
                _isWeakSummary(introExtracts[entry.key], entry.value.title),
          )
          .map((entry) => entry.key)
          .toList(growable: false);

      if (weakQids.isNotEmpty) {
        fullExtracts = await _batchFetchExtracts(
          resolvedByQid: {
            for (final qid in weakQids)
              if (resolved.containsKey(qid)) qid: resolved[qid]!,
          },
          introOnly: false,
        );
        _logger.log(
          'Batch fetched full extracts for ${fullExtracts.length}/${weakQids.length} weak intro entries',
        );
      }
    }

    // Step 4: combine into PoiWikiPreview results.
    final result = <String, PoiWikiPreview>{};
    for (final entry in resolved.entries) {
      final qid = entry.key;
      final wiki = entry.value;
      final htmlPreview = htmlByQid[qid];
      final htmlBasedFullText = (htmlPreview?.plainText ?? '').trim();
      final selectedSummary = _selectBestSummary(
        title: wiki.title,
        introSummary: introExtracts[qid],
        fullSummary: htmlBasedFullText.isNotEmpty
            ? htmlBasedFullText
            : fullExtracts[qid],
        wikidataDescription: wiki.description,
      );
      result[qid] = PoiWikiPreview(
        qid: qid,
        title: wiki.title,
        summary: _applyContentLengthPolicy(selectedSummary),
        htmlContent: htmlPreview?.html ?? '',
        sourceUrl: _buildWikipediaArticleUrl(
          languageCode: wiki.languageCode,
          title: wiki.title,
        ),
        languageCode: wiki.languageCode,
      );
    }
    return result;
  }

  /// Resolves QIDs to Wikipedia titles in batches of [_maxBatchSize].
  Future<Map<String, _ResolvedWikiTitle>> _batchResolveQids({
    required List<String> qids,
    required String preferredLanguageCode,
  }) async {
    final result = <String, _ResolvedWikiTitle>{};

    for (var i = 0; i < qids.length; i += _maxBatchSize) {
      final chunk = qids.sublist(i, min(i + _maxBatchSize, qids.length));
      final uri = Uri.https('www.wikidata.org', '/w/api.php', {
        'action': 'wbgetentities',
        'ids': chunk.join('|'),
        'props': 'sitelinks|descriptions',
        'format': 'json',
        'formatversion': '2',
      });

      try {
        final response = await _getWithThrottle(uri);
        if (response.statusCode != 200) {
          _logger.error(
            'Wikidata batch HTTP ${response.statusCode} for chunk $i–${i + chunk.length}',
          );
          continue;
        }

        final dynamic body = jsonDecode(response.body);
        if (body is! Map) continue;
        final entities = body['entities'];
        if (entities is! Map) continue;

        for (final qid in chunk) {
          final entity = entities[qid];
          if (entity is! Map) continue;
          final sitelinks = entity['sitelinks'];
          if (sitelinks is! Map) continue;
          final resolvedSitelink = _pickBestSitelink(
            sitelinks: sitelinks,
            preferredLanguageCode: preferredLanguageCode,
          );
          if (resolvedSitelink == null) continue;
          final descriptions = entity['descriptions'];
          final description = descriptions is Map
              ? _pickBestDescription(
                  descriptions: descriptions,
                  preferredLanguageCode: preferredLanguageCode,
                )
              : null;
          result[qid] = _ResolvedWikiTitle(
            title: resolvedSitelink.title,
            languageCode: resolvedSitelink.languageCode,
            description: description,
          );
        }
      } catch (e) {
        _logger.error('Wikidata batch resolve error at chunk $i: $e');
      }
    }

    return result;
  }

  /// Fetches Wikipedia lead sections (exintro) for all resolved titles.
  /// Groups titles by language code and batches up to [_maxBatchSize] per request.
  Future<Map<String, String>> _batchFetchExtracts({
    required Map<String, _ResolvedWikiTitle> resolvedByQid,
    required bool introOnly,
  }) async {
    // Group: languageCode → { qid: title }
    final byLang = <String, Map<String, String>>{};
    for (final entry in resolvedByQid.entries) {
      byLang.putIfAbsent(entry.value.languageCode, () => {}).addAll({
        entry.key: entry.value.title,
      });
    }

    final result = <String, String>{};

    for (final langEntry in byLang.entries) {
      final languageCode = langEntry.key;
      final qidToTitle = langEntry.value;
      // Reverse map: Wikipedia title → qid (used to re-join after redirect resolution)
      final titleToQid = {for (final e in qidToTitle.entries) e.value: e.key};
      final titles = qidToTitle.values.toList(growable: false);
      // MediaWiki `extracts` module returns incomplete data when requesting
      // multiple non-intro full extracts in one `titles=...` query.
      // Keep intro requests batched, but fetch full-text one title per request
      // to guarantee complete coverage for offline POI descriptions.
      final batchSize = introOnly ? _maxBatchSize : 1;

      for (var i = 0; i < titles.length; i += batchSize) {
        final chunk = titles.sublist(i, min(i + batchSize, titles.length));
        final uri = Uri.https('$languageCode.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'prop': 'extracts',
          if (introOnly) 'exintro': '1',
          'explaintext': '1',
          'redirects': '1',
          'titles': chunk.join('|'),
          'format': 'json',
          'formatversion': '2',
        });

        try {
          final response = await _getWithThrottle(uri);
          if (response.statusCode != 200) {
            _logger.error(
              'Wikipedia extract HTTP ${response.statusCode} for $languageCode chunk $i',
            );
            continue;
          }

          final dynamic body = jsonDecode(response.body);
          if (body is! Map) continue;
          final query = body['query'];
          if (query is! Map) continue;

          // Build normalization + redirect chain: inputTitle → finalPageTitle
          final titleMapping = <String, String>{};
          for (final list in [query['normalized'], query['redirects']]) {
            if (list is! List) continue;
            for (final item in list.whereType<Map>()) {
              final from = (item['from'] ?? '').toString();
              final to = (item['to'] ?? '').toString();
              if (from.isNotEmpty && to.isNotEmpty) titleMapping[from] = to;
            }
          }

          String resolveTitle(String input) {
            var current = input;
            final seen = <String>{current};
            while (titleMapping.containsKey(current)) {
              current = titleMapping[current]!;
              if (!seen.add(current)) break;
            }
            return current;
          }

          final pages = query['pages'];
          if (pages is! List) continue;

          // Index pages by their final title.
          final extractByTitle = <String, String>{};
          for (final page in pages.whereType<Map>()) {
            if ((page['missing'] ?? false) == true) continue;
            final pageTitle = (page['title'] ?? '').toString();
            final extract = (page['extract'] ?? '').toString().trim();
            if (pageTitle.isNotEmpty) extractByTitle[pageTitle] = extract;
          }

          // Map back to QIDs via original title → resolved title → extract.
          for (final originalTitle in chunk) {
            final qid = titleToQid[originalTitle];
            if (qid == null) continue;
            final finalTitle = resolveTitle(originalTitle);
            final extract = extractByTitle[finalTitle];
            if (extract != null && extract.isNotEmpty) result[qid] = extract;
          }
        } catch (e) {
          _logger.error(
            'Wikipedia extract batch error for $languageCode chunk $i: $e',
          );
        }
      }
    }

    return result;
  }

  Future<Map<String, _HtmlPreview>> _batchFetchHtml({
    required Map<String, _ResolvedWikiTitle> resolvedByQid,
  }) async {
    final result = <String, _HtmlPreview>{};
    for (final entry in resolvedByQid.entries) {
      final qid = entry.key;
      final resolved = entry.value;
      final html = await _fetchAndSanitizeHtml(
        title: resolved.title,
        languageCode: resolved.languageCode,
      );
      if (html != null && html.html.isNotEmpty) {
        result[qid] = html;
      }
    }
    return result;
  }

  Future<_HtmlPreview?> _fetchAndSanitizeHtml({
    required String title,
    required String languageCode,
  }) async {
    final uri = Uri.https('$languageCode.wikipedia.org', '/w/api.php', {
      'action': 'parse',
      'page': title,
      'prop': 'text',
      'redirects': '1',
      'disableeditsection': '1',
      'disabletoc': '1',
      'format': 'json',
      'formatversion': '2',
    });

    try {
      final response = await _getWithThrottle(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final dynamic body = jsonDecode(response.body);
      if (body is! Map) return null;
      final parse = body['parse'];
      if (parse is! Map) return null;
      final rawHtml = (parse['text'] ?? '').toString().trim();
      if (rawHtml.isEmpty) return null;
      return _sanitizeAndWrapHtml(rawHtml, languageCode: languageCode);
    } catch (e) {
      _logger.error('POI HTML fetch failed for "$title" ($languageCode): $e');
      return null;
    }
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  _ResolvedWikiTitle? _pickBestSitelink({
    required Map<dynamic, dynamic> sitelinks,
    required String preferredLanguageCode,
  }) {
    final preferredSite = '${preferredLanguageCode}wiki';

    final preferredTitle = _extractSitelinkTitle(sitelinks, preferredSite);
    if (preferredTitle != null) {
      return _ResolvedWikiTitle(
        title: preferredTitle,
        languageCode: preferredLanguageCode,
      );
    }

    final enTitle = _extractSitelinkTitle(sitelinks, 'enwiki');
    if (enTitle != null) {
      return _ResolvedWikiTitle(title: enTitle, languageCode: 'en');
    }

    for (final entry in sitelinks.entries) {
      final key = entry.key.toString();
      if (!key.endsWith('wiki')) continue;
      final title = _extractSitelinkTitle(sitelinks, key);
      if (title == null) continue;
      final langCode = key.replaceFirst(RegExp(r'wiki$'), '');
      if (langCode.isEmpty) continue;
      return _ResolvedWikiTitle(title: title, languageCode: langCode);
    }

    return null;
  }

  String? _pickBestDescription({
    required Map<dynamic, dynamic> descriptions,
    required String preferredLanguageCode,
  }) {
    final preferred = _extractDescription(descriptions, preferredLanguageCode);
    if (preferred != null) return preferred;

    final en = _extractDescription(descriptions, 'en');
    if (en != null) return en;

    for (final key in descriptions.keys) {
      final candidate = _extractDescription(descriptions, key.toString());
      if (candidate != null) return candidate;
    }
    return null;
  }

  String? _extractDescription(Map<dynamic, dynamic> descriptions, String key) {
    final dynamic entry = descriptions[key];
    if (entry is! Map) return null;
    final value = (entry['value'] ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  bool _isWeakSummary(String? summary, String title) {
    final normalizedSummary = _normalizeSummary(summary);
    if (normalizedSummary.isEmpty) return true;

    final normalizedSummaryComparable = _normalizeComparableText(
      normalizedSummary,
    );
    final normalizedTitleComparable = _normalizeComparableText(title);
    if (normalizedSummaryComparable == normalizedTitleComparable) return true;

    return normalizedSummary.length <
        PoiPreviewContentConfig.weakSummaryMinChars;
  }

  String _selectBestSummary({
    required String title,
    String? introSummary,
    String? fullSummary,
    String? wikidataDescription,
  }) {
    if (!_isWeakSummary(fullSummary, title)) {
      return _normalizeSummary(fullSummary);
    }
    if (!_isWeakSummary(introSummary, title)) {
      return _normalizeSummary(introSummary);
    }
    final normalizedDescription = _normalizeSummary(wikidataDescription);
    if (normalizedDescription.isNotEmpty) {
      return normalizedDescription;
    }
    return _normalizeSummary(title);
  }

  String _applyContentLengthPolicy(String value) {
    final normalized = _normalizeSummary(value);
    final mode = PoiPreviewContentConfig.mode;
    switch (mode) {
      case PoiPreviewContentMode.summary:
        return _truncateSummarySoft(
          normalized,
          targetChars: PoiPreviewContentConfig.summaryTargetChars,
          maxChars: PoiPreviewContentConfig.summaryMaxChars,
        );
      case PoiPreviewContentMode.fullText:
        final targetChars = PoiPreviewContentConfig.fullTextTargetChars;
        final maxChars = PoiPreviewContentConfig.fullTextMaxChars;
        if (targetChars == null || maxChars == null) {
          return normalized;
        }
        return _truncateSummarySoft(
          normalized,
          targetChars: targetChars,
          maxChars: maxChars,
        );
    }
  }

  String _truncateSummarySoft(
    String normalized, {
    required int targetChars,
    required int maxChars,
  }) {
    if (normalized.length <= targetChars) return normalized;

    final preferredEnd = _findSentenceBoundary(
      text: normalized,
      from: targetChars,
      to: maxChars,
    );
    if (preferredEnd != null) {
      return normalized.substring(0, preferredEnd).trimRight();
    }

    final hardEnd = normalized.length < maxChars ? normalized.length : maxChars;
    final wordSafeEnd = normalized.lastIndexOf(' ', hardEnd);
    if (wordSafeEnd > 0) {
      return normalized.substring(0, wordSafeEnd).trimRight();
    }
    return normalized.substring(0, hardEnd).trimRight();
  }

  int? _findSentenceBoundary({
    required String text,
    required int from,
    required int to,
  }) {
    if (text.isEmpty) return null;
    final safeFrom = from.clamp(0, text.length).toInt();
    final safeTo = to.clamp(0, text.length).toInt();
    if (safeFrom >= safeTo) return null;

    for (var i = safeFrom; i < safeTo; i++) {
      final char = text[i];
      if (char != '.' && char != '!' && char != '?') continue;
      final nextIndex = i + 1;
      if (nextIndex >= text.length || text[nextIndex] == ' ') {
        return nextIndex;
      }
    }
    return null;
  }

  String _normalizeSummary(String? value) {
    if (value == null) return '';
    final withoutWikiMarkers = WikiTextUtils.stripSectionMarkers(value);
    final normalizedLines = withoutWikiMarkers
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .toList(growable: false);

    final buffer = StringBuffer();
    var previousWasEmpty = false;
    for (final line in normalizedLines) {
      if (line.isEmpty) {
        if (!previousWasEmpty) {
          if (buffer.isNotEmpty) {
            buffer.write('\n\n');
          }
          previousWasEmpty = true;
        }
        continue;
      }

      if (buffer.isNotEmpty && !previousWasEmpty) {
        buffer.write('\n');
      }
      buffer.write(line);
      previousWasEmpty = false;
    }

    return buffer.toString().trim();
  }

  String _normalizeComparableText(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  _HtmlPreview? _sanitizeAndWrapHtml(
    String rawHtml, {
    required String languageCode,
  }) {
    final fragment = html_parser.parseFragment(rawHtml);
    _removeNoisyBlocks(fragment);
    final contentRoot = dom.Element.tag('div')
      ..classes.add('poi-offline-content')
      ..nodes.addAll(fragment.nodes);
    _sanitizeTree(contentRoot, languageCode: languageCode);
    final htmlBody = contentRoot.innerHtml.trim();
    final plainText = _normalizeSummary(contentRoot.text);
    if (htmlBody.isEmpty) return null;
    return _HtmlPreview(
      html: _wrapAsOfflineHtmlDocument(htmlBody),
      plainText: plainText,
    );
  }

  void _removeNoisyBlocks(dom.Node root) {
    if (root is! dom.Element && root is! dom.DocumentFragment) return;
    final selectors = <String>[
      '.infobox',
      '.vertical-navbox',
      '.navbox',
      '.metadata',
      '.mw-editsection',
      '.mw-references-wrap',
      '.reference',
      // Remove media wrappers/captions so they do not pollute POI summaries.
      '.thumb',
      '.thumbinner',
      '.thumbcaption',
      '.thumbcaption .magnify',
      'figure',
      'figcaption',
      '.gallery',
      '.gallerybox',
      '.gallerytext',
      '.hatnote',
      'table',
      'style',
      'script',
      'noscript',
      'img',
    ];
    for (final selector in selectors) {
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
      if (child is! dom.Element) continue;
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

  void _sanitizeAttributes(
    dom.Element element, {
    required String languageCode,
  }) {
    final tag = (element.localName ?? '').toLowerCase();
    final allowed = <String>{};
    if (tag == 'a') {
      allowed.addAll(const {'href', 'title'});
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

  String _wrapAsOfflineHtmlDocument(String contentBody) {
    return '''<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
  html, body {
    margin: 0;
    padding: 0;
  }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.55;
    color: #1f2937;
    background: transparent;
  }
  .poi-offline-content {
    margin: 0;
    padding: 0;
  }
  p, li, blockquote, pre {
    font-size: 15px;
  }
  h2, h3, h4 {
    margin: 18px 0 10px;
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

  Future<http.Response> _getWithThrottle(Uri uri) async {
    await _throttleRequests();
    return _apiClient.get(uri, timeout: _requestTimeout);
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

  String? _extractSitelinkTitle(Map<dynamic, dynamic> sitelinks, String key) {
    final dynamic entry = sitelinks[key];
    if (entry is! Map) return null;
    final title = (entry['title'] ?? '').toString().trim();
    return title.isEmpty ? null : title;
  }

  String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty) return 'en';
    final parts = normalized.split(RegExp(r'[-_]'));
    return parts.first.isEmpty ? 'en' : parts.first;
  }

  String _buildWikipediaArticleUrl({
    required String languageCode,
    required String title,
  }) {
    final articlePath = title.trim().replaceAll(' ', '_');
    return 'https://$languageCode.wikipedia.org/wiki/${Uri.encodeComponent(articlePath)}';
  }
}

class _ResolvedWikiTitle {
  const _ResolvedWikiTitle({
    required this.title,
    required this.languageCode,
    this.description,
  });

  final String title;
  final String languageCode;
  final String? description;
}

class _HtmlPreview {
  const _HtmlPreview({
    required this.html,
    required this.plainText,
  });

  final String html;
  final String plainText;
}
