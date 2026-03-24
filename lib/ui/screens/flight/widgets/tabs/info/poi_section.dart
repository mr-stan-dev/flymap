import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class PoiSection extends StatelessWidget {
  const PoiSection({required this.poi, super.key});

  final List<FlightPoi> poi;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: 'Points of Interest',
      child: poi.isEmpty
          ? const Text('No POIs available yet.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in poi)
                  if (item.name.trim().isNotEmpty)
                    ActionChip(
                      label: Text(item.name),
                      onPressed: () => _openPoiDetails(context, item),
                    ),
              ],
            ),
    );
  }

  void _openPoiDetails(BuildContext context, FlightPoi item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PoiDetailsSheet(item: item),
    );
  }
}

class _PoiDetailsSheet extends StatelessWidget {
  const _PoiDetailsSheet({required this.item});

  final FlightPoi item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (item.type.trim().isNotEmpty) Text('Type: ${item.type}'),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description),
          ],
          if (item.flyView.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Fly-over: ${item.flyView}'),
          ],
          if (item.wiki.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(item.wiki),
          ],
        ],
      ),
    );
  }
}
