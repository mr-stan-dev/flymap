import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/common/html_content_page.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';
import 'package:flymap/utils/wiki_text_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

enum PoiPreviewActionMode { cancelAndOpen, openOnly, none }

Future<void> showPoiPreviewDialog({
  required BuildContext context,
  required String name,
  required String typeRaw,
  required String qid,
  PoiPreviewActionMode actionMode = PoiPreviewActionMode.cancelAndOpen,
  GetPoiWikiPreviewUseCase? wikiPreviewUseCase,
  PoiWikiPreview? preloadedPreview,
}) async {
  if (name.trim().isEmpty) return;
  final useCase = wikiPreviewUseCase ?? GetIt.I.get<GetPoiWikiPreviewUseCase>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => PoiPreviewBottomSheet(
      name: name,
      typeRaw: typeRaw,
      qid: qid,
      preferredLanguageCode: Localizations.localeOf(context).languageCode,
      wikiPreviewUseCase: useCase,
      preloadedPreview: preloadedPreview,
      actionMode: actionMode,
    ),
  );
}

class PoiPreviewBottomSheet extends StatefulWidget {
  const PoiPreviewBottomSheet({
    required this.name,
    required this.typeRaw,
    required this.qid,
    required this.preferredLanguageCode,
    required this.wikiPreviewUseCase,
    required this.actionMode,
    this.preloadedPreview,
    super.key,
  });

  final String name;
  final String typeRaw;
  final String qid;
  final String preferredLanguageCode;
  final GetPoiWikiPreviewUseCase wikiPreviewUseCase;
  final PoiPreviewActionMode actionMode;
  final PoiWikiPreview? preloadedPreview;

  @override
  State<PoiPreviewBottomSheet> createState() => _PoiPreviewBottomSheetState();
}

class _PoiPreviewBottomSheetState extends State<PoiPreviewBottomSheet> {
  static const _weakSummaryMinChars = 120;
  PoiWikiPreview? _preview;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedPreview != null) {
      _preview = widget.preloadedPreview;
      if (_shouldRefreshPreloadedPreview(widget.preloadedPreview!)) {
        unawaited(_loadPreview());
      }
    } else {
      unawaited(_loadPreview());
    }
  }

  Future<void> _loadPreview() async {
    if (widget.qid.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final preview = await widget.wikiPreviewUseCase.call(
        qid: widget.qid,
        preferredLanguageCode: widget.preferredLanguageCode,
      );
      if (!mounted) return;
      if (preview != null) {
        setState(() {
          _preview = preview;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _preview == null ? e : null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _formatPoiType(widget.typeRaw, context);
    final sourceUrl = _preview?.sourceUrl.trim() ?? '';
    final summary = (_preview?.summary ?? '').trim();
    final fallbackTitle = (_preview?.title ?? '').trim();
    final htmlContent = (_preview?.htmlContent ?? '').trim();
    final rawBodyText = summary.isNotEmpty ? summary : fallbackTitle;
    final previewText = WikiTextUtils.stripSectionMarkers(rawBodyText);
    final hasHtml = htmlContent.isNotEmpty;
    final hasOpenWikipediaAction = widget.actionMode != PoiPreviewActionMode.none;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(context.t.flight.info.poiType(type: typeLabel)),
          if (_isLoading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(context.t.common.loading)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (previewText.isNotEmpty)
            Text(
              previewText,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
              ),
            )
          else if (!_isLoading && _error != null)
            Text(
              context.t.createFlight.errors.overviewUnavailableContinue,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (hasHtml || hasOpenWikipediaAction) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasHtml)
                  TextButton(
                    onPressed: () => _openReadMore(
                      context: context,
                      htmlContent: htmlContent,
                      sourceUrl: sourceUrl,
                    ),
                    child: Text(context.t.common.readMore),
                  ),
                if (hasHtml && hasOpenWikipediaAction) const Spacer(),
                if (hasOpenWikipediaAction)
                  TextButton(
                    onPressed: sourceUrl.isEmpty
                        ? null
                        : () => _openSourceUrl(context, sourceUrl),
                    child: Text('${context.t.home.open} Wikipedia'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReadMore({
    required BuildContext context,
    required String htmlContent,
    required String sourceUrl,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HtmlContentPage(
          title: widget.name,
          htmlContent: htmlContent,
          sourceUrl: sourceUrl,
        ),
      ),
    );
  }

  bool _shouldRefreshPreloadedPreview(PoiWikiPreview preview) {
    if (widget.qid.trim().isEmpty) return false;
    if (preview.htmlContent.trim().isNotEmpty) return false;
    final summary = preview.summary.trim();
    if (summary.isEmpty) return true;
    final title = preview.title.trim();
    if (_normalizeComparable(summary) == _normalizeComparable(title)) {
      return true;
    }
    return summary.length < _weakSummaryMinChars;
  }

  String _normalizeComparable(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openSourceUrl(BuildContext context, String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.settings.couldNotOpenUrl(url: sourceUrl)),
        ),
      );
    }
  }

  String _formatPoiType(String raw, BuildContext context) {
    if (raw.trim().isEmpty) return context.t.subscription.unknown;
    final normalized = raw.trim().replaceAll('_', ' ');
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }
}
