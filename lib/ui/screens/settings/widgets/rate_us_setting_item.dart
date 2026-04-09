import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/rating/rate_store_launcher.dart';
import 'package:get_it/get_it.dart';

class RateUsSettingItem extends StatelessWidget {
  const RateUsSettingItem({super.key});

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
    final opened = await GetIt.I.get<RateStoreLauncher>().openStoreListing();
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.settings.couldNotOpenStorePage)),
    );
  }
}
