import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';

class FlightSearchDownloadingView extends StatelessWidget {
  const FlightSearchDownloadingView({
    required this.state,
    required this.onCancel,
    super.key,
  });

  final FlightSearchScreenState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final stageLine = _downloadStageLine(state);
    final showProgressBar =
        state.downloadStage != DownloadStage.downloadingArticles;
    final title = state.downloadStage == DownloadStage.downloadingArticles
        ? context.t.createFlight.downloading.articlesTitle
        : context.t.createFlight.downloading.mapTitle;

    return Column(
      children: [
        Expanded(
          child: ProgressStateView(
            title: title,
            progress: state.downloadProgress,
            showProgress: showProgressBar,
            secondaryLine: stageLine,
            trailingAction: SecondaryButton(
              onPressed: onCancel,
              leadingIcon: Icons.close_rounded,
              label: context.t.createFlight.downloading.cancelDownload,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(DsSpacing.md),
          child: InlineMessage(
            message: context.t.createFlight.downloading.doNotClose,
            tone: DsMessageTone.info,
          ),
        ),
      ],
    );
  }

  String _downloadStageLine(FlightSearchScreenState state) {
    switch (state.downloadStage) {
      case DownloadStage.downloadingArticles:
        final total = state.articleDownloadTotal;
        final completed = state.articleDownloadCompleted;
        final failed = state.articleDownloadFailed;
        if (total <= 0) return t.createFlight.downloading.preparingArticles;
        if (failed > 0) {
          return t.createFlight.downloading.articlesProgressWithFailed(
            completed: completed,
            total: total,
            failed: failed,
          );
        }
        return t.createFlight.downloading.articlesProgress(
          completed: completed,
          total: total,
        );
      case DownloadStage.initializing:
        return t.createFlight.downloading.preparingMap;
      case DownloadStage.computingTiles:
        return state.downloadTileCount == null
            ? t.createFlight.downloading.computingTiles
            : t.createFlight.downloading.computingTilesWithCount(
                count: state.downloadTileCount!,
              );
      case DownloadStage.startingWorkers:
        return t.createFlight.downloading.preparingForDownload;
      case DownloadStage.downloading:
        return t.createFlight.downloading.downloaded(
          size: _formatDownloadedMb(state.downloadedBytes),
        );
      case DownloadStage.finalizing:
        return t.createFlight.downloading.finalizing;
      case DownloadStage.verifying:
        return t.createFlight.downloading.verifying;
      case DownloadStage.completed:
      case DownloadStage.failed:
      case DownloadStage.idle:
        return t.createFlight.downloading.downloaded(
          size: _formatDownloadedMb(state.downloadedBytes),
        );
    }
  }

  String _formatDownloadedMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
