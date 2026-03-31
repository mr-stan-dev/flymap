import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightSearchWikipediaArticlesStep extends StatelessWidget {
  const FlightSearchWikipediaArticlesStep({
    required this.state,
    required this.onToggleArticle,
    required this.onToggleAll,
    required this.onStartDownload,
    super.key,
  });

  final FlightSearchScreenState state;
  final ValueChanged<String> onToggleArticle;
  final VoidCallback onToggleAll;
  final VoidCallback onStartDownload;

  static const _wikipediaLogoIconAsset =
      'assets/images/wikipedia_logo_icon.webp';

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedArticleUrls.length;
    final estimatedSizeRange = MapUtils.estimatedDownloadSizeRangeLabel(
      route: state.flightRoute,
      selectedArticlesCount: selectedCount,
    );
    final candidates = state.articleCandidates;
    final isLoading = state.isWikiSuggestionsLoading;
    final hasCandidates = candidates.isNotEmpty;
    final selectedSet = state.selectedArticleUrls.toSet();
    final allSelected =
        hasCandidates &&
        candidates.every((candidate) => selectedSet.contains(candidate.url));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Download articles to read during the flight',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isLoading
                    ? 'Finding route-related articles...'
                    : hasCandidates
                    ? 'Based on your route we found ${candidates.length} articles which may be interesting for you. Select to download them for offline reading'
                    : 'No route-related Wikipedia articles found. You can continue with map download only.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ] else if (hasCandidates) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '$selectedCount selected',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onToggleAll,
                      icon: Icon(
                        allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                      ),
                      label: Text(allSelected ? 'Unselect all' : 'Select all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...candidates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final candidate = entry.value;
                  final selected = state.selectedArticleUrls.contains(
                    candidate.url,
                  );
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _wikiLogoBadge(context),
                        title: Text(
                          candidate.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openUrl(context, candidate.url),
                          child: Text(
                            candidate.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: (_) => onToggleArticle(candidate.url),
                        ),
                        onTap: () => onToggleArticle(candidate.url),
                      ),
                      if (index < candidates.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estimated download size: $estimatedSizeRange',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: PrimaryButton(
                    onPressed: isLoading ? null : onStartDownload,
                    label: isLoading
                        ? 'Loading article suggestions...'
                        : selectedCount > 0
                        ? 'Download map + $selectedCount article${selectedCount == 1 ? '' : 's'}'
                        : 'Download map',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _wikiLogoBadge(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadii.sm),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.asset(
          _wikipediaLogoIconAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                'W',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }
}
