import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_capture_preview_screen.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_folder_screen.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/media/widgets/media_shared.dart';
import 'package:get_it/get_it.dart';

class MediaTab extends StatelessWidget {
  const MediaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MediaTabCubit>(
      create: (_) => MediaTabCubit(
        repository: GetIt.I.get(),
        flightRepository: GetIt.I.get(),
        metricUnitsRepository: GetIt.I.get(),
      )..load(),
      child: const _MediaTabView(),
    );
  }
}

class _MediaTabView extends StatelessWidget {
  const _MediaTabView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaTabCubit, MediaTabState>(
      builder: (context, state) {
        switch (state) {
          case MediaTabLoading():
            return LoadingStateView(title: context.t.media.loading);
          case MediaTabError(:final message):
            return ErrorStateView(
              title: context.t.media.failedToLoad,
              message: message,
              retryLabel: context.t.common.retry,
              onRetry: context.read<MediaTabCubit>().load,
            );
          case MediaTabLoaded(:final folders, :final dateDisplayFormat):
            return _MediaLoadedView(
              folders: folders,
              dateDisplayFormat: dateDisplayFormat,
            );
        }
      },
    );
  }
}

class _MediaLoadedView extends StatelessWidget {
  const _MediaLoadedView({
    required this.folders,
    required this.dateDisplayFormat,
  });

  static const _viewAllThreshold = 10;

  final List<MediaCaptureFolder> folders;
  final DateDisplayFormat dateDisplayFormat;

  @override
  Widget build(BuildContext context) {
    final noFlightFolder = _findNoFlightFolder(folders);
    final flightFolders = [
      for (final folder in folders)
        if (folder.hasFlightContext) folder,
    ];

    if (noFlightFolder == null && flightFolders.isEmpty) {
      return const _MediaEmptyState();
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          if (noFlightFolder != null) ...[
            _MediaSectionHeader(
              title: context.t.media.groupNoFlight,
              subtitle: context.t.media.groupNoFlightSubtitle,
              actionLabel: noFlightFolder.captures.length > _viewAllThreshold
                  ? context.t.home.viewAll
                  : null,
              onActionTap: noFlightFolder.captures.length > _viewAllThreshold
                  ? () => _openFolder(context, noFlightFolder)
                  : null,
            ),
            _MediaHorizontalCaptureList(
              captures: noFlightFolder.captures,
              onCaptureTap: (capture) => _openCapturePreview(
                context,
                captures: noFlightFolder.captures,
                initialCapture: capture,
              ),
            ),
            const SizedBox(height: 20),
          ],
          for (final folder in flightFolders) ...[
            _MediaSectionHeader(
              title: folder.title,
              dateLabel: _formatGroupDate(
                folder.coverCapture.capturedAt,
                dateDisplayFormat: dateDisplayFormat,
              ),
              subtitle: folder.subtitle,
              actionLabel: folder.captures.length > _viewAllThreshold
                  ? context.t.home.viewAll
                  : null,
              onActionTap: folder.captures.length > _viewAllThreshold
                  ? () => _openFolder(context, folder)
                  : null,
            ),
            _MediaHorizontalCaptureList(
              captures: folder.captures,
              onCaptureTap: (capture) => _openCapturePreview(
                context,
                captures: folder.captures,
                initialCapture: capture,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  MediaCaptureFolder? _findNoFlightFolder(List<MediaCaptureFolder> folders) {
    for (final folder in folders) {
      if (!folder.hasFlightContext) return folder;
    }
    return null;
  }

  String _formatGroupDate(
    DateTime value, {
    required DateDisplayFormat dateDisplayFormat,
  }) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    final month = monthNames[local.month - 1];
    return dateDisplayFormat == DateDisplayFormat.international
        ? '${local.day} $month ${local.year}'
        : '$month ${local.day}, ${local.year}';
  }

  void _openFolder(BuildContext context, MediaCaptureFolder folder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<MediaTabCubit>(),
          child: MediaFolderScreen(folder: folder),
        ),
      ),
    );
  }

  void _openCapturePreview(
    BuildContext context, {
    required List<SkyCameraMediaItem> captures,
    required SkyCameraMediaItem initialCapture,
  }) {
    final mediaTabCubit = context.read<MediaTabCubit>();
    Navigator.of(context).push<Set<String>>(
      MaterialPageRoute<Set<String>>(
        builder: (_) => MediaCapturePreviewScreen(
          captures: captures,
          initialCaptureId: initialCapture.id,
          onDelete: (captureId) => mediaTabCubit.deleteCaptureIds([captureId]),
        ),
      ),
    );
  }
}

class _MediaEmptyState extends StatelessWidget {
  const _MediaEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  context.t.media.emptyTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.t.media.emptySubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaSectionHeader extends StatelessWidget {
  const _MediaSectionHeader({
    required this.title,
    this.dateLabel,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? dateLabel;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (dateLabel != null && dateLabel!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        dateLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _MediaHorizontalCaptureList extends StatelessWidget {
  const _MediaHorizontalCaptureList({
    required this.captures,
    required this.onCaptureTap,
  });

  final List<SkyCameraMediaItem> captures;
  final ValueChanged<SkyCameraMediaItem> onCaptureTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: captures.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final capture = captures[index];
          return _MediaStripTile(
            capture: capture,
            onTap: () => onCaptureTap(capture),
          );
        },
      ),
    );
  }
}

class _MediaStripTile extends StatelessWidget {
  const _MediaStripTile({required this.capture, required this.onTap});

  final SkyCameraMediaItem capture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('media.strip_thumbnail_${capture.id}'),
      width: 112,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaCaptureThumbnailImage(path: capture.galleryImagePath),
              if (capture.isVideo)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 7,
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
