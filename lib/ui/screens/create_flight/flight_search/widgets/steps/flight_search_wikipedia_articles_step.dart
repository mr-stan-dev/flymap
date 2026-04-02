import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/pro_limits.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:flymap/ui/widgets/wikipedia_logo_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightSearchWikipediaArticlesStep extends StatelessWidget {
  const FlightSearchWikipediaArticlesStep({
    required this.state,
    required this.isProUser,
    required this.onToggleArticle,
    required this.onToggleAll,
    required this.onStartDownload,
    super.key,
  });

  final FlightSearchScreenState state;
  final bool isProUser;
  final ValueChanged<String> onToggleArticle;
  final VoidCallback onToggleAll;
  final VoidCallback onStartDownload;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedArticleUrls.length;
    final estimatedSizeRange = MapUtils.estimatedDownloadSizeRangeLabel(
      route: state.flightRoute,
      mapDetailLevel: state.selectedMapDetailLevel,
      selectedArticlesCount: selectedCount,
    );
    final candidates = state.articleCandidates;
    final isLoading = state.isWikiSuggestionsLoading;
    final hasCandidates = candidates.isNotEmpty;
    final selectedSet = state.selectedArticleUrls.toSet();
    final isFreeOverLimit =
        selectedCount > ProLimits.freeWikiArticlesSelectionLimit;
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
                context.t.createFlight.wikipedia.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isLoading
                    ? context.t.createFlight.wikipedia.loadingIntro
                    : hasCandidates
                    ? context.t.createFlight.wikipedia.foundIntro(
                        count: candidates.length,
                      )
                    : context.t.createFlight.wikipedia.emptyIntro,
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
                      context.t.createFlight.wikipedia.selectedCount(
                        count: selectedCount,
                      ),
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
                      label: Text(
                        allSelected
                            ? context.t.createFlight.wikipedia.unselectAll
                            : context.t.createFlight.wikipedia.selectAll,
                      ),
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
                        leading: const WikipediaLogoAvatar(size: 36),
                        title: Text(
                          candidate.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openUrl(context, candidate.url),
                          child: Builder(
                            builder: (context) {
                              final linkColor = Theme.of(
                                context,
                              ).colorScheme.primary;
                              return Text(
                                candidate.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: linkColor,
                                      decoration: TextDecoration.underline,
                                      decorationColor: linkColor,
                                    ),
                              );
                            },
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProUser && isFreeOverLimit) ...[
                ProActiveBlock(
                  title: context.t.createFlight.wikipedia.proActiveTitle,
                  message: context.t.createFlight.wikipedia.proActiveMessage,
                ),
                const SizedBox(height: 8),
              ],
              !isProUser && isFreeOverLimit
                  ? Text(
                      context.t.createFlight.wikipedia.freeLimitHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DsBrandColors.proAmber,
                      ),
                    )
                  : Text(
                      context.t.createFlight.wikipedia.estimatedDownloadSize(
                        size: estimatedSizeRange,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: !isProUser && isFreeOverLimit
                    ? PremiumButton(
                        label: context.t.createFlight.wikipedia.upgrade,
                        icon: Icons.workspace_premium_rounded,
                        onPressed: isLoading ? null : onStartDownload,
                      )
                    : PrimaryButton(
                        onPressed: isLoading ? null : onStartDownload,
                        label: isLoading
                            ? context
                                  .t
                                  .createFlight
                                  .wikipedia
                                  .loadingSuggestions
                            : selectedCount > 0
                            ? selectedCount == 1
                                  ? context
                                        .t
                                        .createFlight
                                        .wikipedia
                                        .downloadMapPlusOne
                                  : context.t.createFlight.wikipedia
                                        .downloadMapPlusMany(
                                          count: selectedCount,
                                        )
                            : context.t.createFlight.wikipedia.downloadMapOnly,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.createFlight.wikipedia.couldNotOpenLink),
        ),
      );
    }
  }
}
