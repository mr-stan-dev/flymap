import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class ProfileHomeAirportPicker extends StatefulWidget {
  const ProfileHomeAirportPicker({
    required this.selectedAirport,
    required this.query,
    required this.isSearchLoading,
    required this.results,
    required this.popular,
    required this.onQueryChanged,
    required this.onSelectAirport,
    required this.onClearSelectedAirport,
    this.errorMessage,
    super.key,
  });

  final Airport? selectedAirport;
  final String query;
  final bool isSearchLoading;
  final List<Airport> results;
  final List<Airport> popular;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(Airport airport) onSelectAirport;
  final Future<void> Function() onClearSelectedAirport;
  final String? errorMessage;

  @override
  State<ProfileHomeAirportPicker> createState() =>
      _ProfileHomeAirportPickerState();
}

class _ProfileHomeAirportPickerState extends State<ProfileHomeAirportPicker> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(covariant ProfileHomeAirportPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query == widget.query) return;
    if (_controller.text == widget.query) return;
    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchInputField(
          controller: _controller,
          hintText: context.t.onboarding.homeAirportHint,
          isSelected: widget.selectedAirport != null,
          onClear: () {
            _controller.clear();
            widget.onQueryChanged('');
          },
          suffixActions: widget.selectedAirport != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.t.onboarding.removeHomeAirport,
                    onPressed: widget.onClearSelectedAirport,
                  ),
                ]
              : const [],
          onChanged: (value) {
            final selectedLabel = widget.selectedAirport == null
                ? null
                : '${widget.selectedAirport!.name} (${widget.selectedAirport!.displayCode})';
            if (widget.selectedAirport != null && value != selectedLabel) {
              widget.onClearSelectedAirport();
            }
            widget.onQueryChanged(value);
          },
        ),
        const SizedBox(height: 12),
        if (widget.errorMessage != null) ...[
          Text(
            widget.errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.isSearchLoading)
          const Center(child: CircularProgressIndicator())
        else if (_controller.text.trim().isNotEmpty)
          widget.results.isEmpty
              ? Text(
                  context.t.onboarding.noHomeAirportFound,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : _SearchResultList(
                  airports: widget.results,
                  onSelectAirport: widget.onSelectAirport,
                )
        else ...[
          if (widget.popular.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.t.createFlight.search.popularAirports,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.popular.map((airport) {
                return SelectionChip(
                  label: context.t.createFlight.search.airportNameCode(
                    name: airport.nameShort,
                    code: airport.displayCode,
                  ),
                  onPressed: () => widget.onSelectAirport(airport),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({
    required this.airports,
    required this.onSelectAirport,
  });

  final List<Airport> airports;
  final Future<void> Function(Airport airport) onSelectAirport;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: airports.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final airport = airports[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () => onSelectAirport(airport),
          title: Text(
            context.t.createFlight.search.airportNameCode(
              name: airport.name,
              code: airport.displayCode,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
