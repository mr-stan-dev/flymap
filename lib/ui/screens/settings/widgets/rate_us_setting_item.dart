import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RateUsSettingItem extends StatelessWidget {
  const RateUsSettingItem({super.key});

  static const String _androidPackageId = 'app.flymap';
  static const String _iosBundleId = 'app.flymap';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListTile(
      leading: const Icon(Icons.star_rate_rounded),
      title: Text(
        context.t.settings.rateUs,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        context.t.settings.rateUsSubtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openRateUs(context),
    );
  }

  Future<void> _openRateUs(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final platform = Theme.of(context).platform;
    final candidates = await _rateUsUrisForPlatform(platform);
    for (final uri in candidates) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(context.t.settings.couldNotOpenStorePage)),
    );
  }

  Future<List<Uri>> _rateUsUrisForPlatform(TargetPlatform platform) async {
    switch (platform) {
      case TargetPlatform.android:
        return [
          Uri.parse('market://details?id=$_androidPackageId'),
          Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackageId',
          ),
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        final trackId = await _lookupIosTrackId();
        if (trackId != null) {
          return [
            Uri.parse(
              'https://apps.apple.com/app/id$trackId?action=write-review',
            ),
            Uri.parse('https://apps.apple.com/app/id$trackId'),
          ];
        }
        return [Uri.parse('https://apps.apple.com/us/search?term=flymap')];
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return [
          Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackageId',
          ),
        ];
    }
  }

  Future<int?> _lookupIosTrackId() async {
    final uri = Uri.parse(
      'https://itunes.apple.com/lookup?bundleId=$_iosBundleId',
    );
    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      if (first is! Map<String, dynamic>) return null;
      final trackId = first['trackId'];
      if (trackId is num) {
        return trackId.toInt();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
