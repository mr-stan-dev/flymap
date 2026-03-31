import 'package:flutter/material.dart';
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
        ? 'Downloading selected articles...'
        : 'Downloading offline map...';

    return ProgressStateView(
      title: title,
      progress: state.downloadProgress,
      showProgress: showProgressBar,
      secondaryLine: stageLine,
      trailingAction: SecondaryButton(
        onPressed: onCancel,
        leadingIcon: Icons.close_rounded,
        label: 'Cancel download',
      ),
    );
  }

  String _downloadStageLine(FlightSearchScreenState state) {
    switch (state.downloadStage) {
      case DownloadStage.downloadingArticles:
        final total = state.articleDownloadTotal;
        final completed = state.articleDownloadCompleted;
        final failed = state.articleDownloadFailed;
        if (total <= 0) return 'Preparing article downloads...';
        if (failed > 0) {
          return 'Articles: $completed/$total ($failed failed)';
        }
        return 'Articles: $completed/$total';
      case DownloadStage.initializing:
        return 'Preparing map download...';
      case DownloadStage.computingTiles:
        return state.downloadTileCount == null
            ? 'Computing map tiles...'
            : 'Computing map tiles (${state.downloadTileCount})...';
      case DownloadStage.startingWorkers:
        return 'Preparing for download...';
      case DownloadStage.downloading:
        return 'Downloaded: ${_formatDownloadedMb(state.downloadedBytes)}';
      case DownloadStage.finalizing:
        return 'Finalizing map package...';
      case DownloadStage.verifying:
        return 'Verifying map package...';
      case DownloadStage.completed:
      case DownloadStage.failed:
      case DownloadStage.idle:
        return 'Downloaded: ${_formatDownloadedMb(state.downloadedBytes)}';
    }
  }

  String _formatDownloadedMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
