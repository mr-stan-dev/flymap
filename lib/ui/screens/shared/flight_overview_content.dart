import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightOverviewContent extends StatelessWidget {
  const FlightOverviewContent({
    required this.overview,
    this.isLoading = false,
    this.errorMessage,
    this.loadingMessage = 'Building route overview...',
    this.emptyMessage = 'Overview is not available yet for this route.',
    super.key,
  });

  final String overview;
  final bool isLoading;
  final String? errorMessage;
  final String loadingMessage;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final content = overview.trim();
    if (isLoading) {
      return _LoadingOverview(message: loadingMessage);
    }
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return _ErrorOverview(message: errorMessage!.trim());
    }
    if (content.isEmpty) {
      return _EmptyOverview(message: emptyMessage);
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final markdown = _normalizeOverview(content);

    return MarkdownBody(
      data: markdown,
      selectable: false,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.45,
        ),
        h1: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        h2: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        h3: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        listBullet: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        blockquote: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
      onTapLink: (text, href, title) {
        final link = href?.trim();
        if (link == null || link.isEmpty) return;
        _openLink(link);
      },
    );
  }

  String _normalizeOverview(String value) {
    final normalizedNewLines = value.replaceAll('\r\n', '\n').trim();
    return normalizedNewLines.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  Future<void> _openLink(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LoadingOverview extends StatelessWidget {
  const _LoadingOverview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _EmptyOverview extends StatelessWidget {
  const _EmptyOverview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorOverview extends StatelessWidget {
  const _ErrorOverview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}
