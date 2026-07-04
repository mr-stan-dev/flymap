import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';

class MediaCaptureThumbnailImage extends StatelessWidget {
  const MediaCaptureThumbnailImage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class MediaSelectionBadge extends StatelessWidget {
  const MediaSelectionBadge({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.black.withValues(alpha: 0.48),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: selected ? 0.0 : 0.28),
          width: 1.4,
        ),
      ),
      child: Icon(
        selected ? Icons.check_rounded : Icons.circle_outlined,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

Future<bool> showMediaDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t.media.deleteAction),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Rect mediaShareRectForContext(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: size.width * 0.5,
    height: 1,
  );
}

String formatMediaTimestamp(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
