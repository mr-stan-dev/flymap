import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class HomeAirportSelector extends StatefulWidget {
  const HomeAirportSelector({
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
  State<HomeAirportSelector> createState() => _HomeAirportSelectorState();
}

class _HomeAirportSelectorState extends State<HomeAirportSelector> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(covariant HomeAirportSelector oldWidget) {
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
    final visiblePopular = widget.popular;

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
          if (widget.results.isNotEmpty)
            _SearchResultList(
              airports: widget.results,
              onSelectAirport: widget.onSelectAirport,
            )
          else ...[
            if (visiblePopular.isNotEmpty) ...[
              _AirportSectionTitle(context.t.onboarding.popularAirports),
              _AirportChipWrap(
                airports: visiblePopular,
                onSelectAirport: widget.onSelectAirport,
              ),
            ],
          ]
        else ...[
          if (visiblePopular.isNotEmpty) ...[
            _AirportSectionTitle(context.t.onboarding.popularAirports),
            _AirportChipWrap(
              airports: visiblePopular,
                onSelectAirport: widget.onSelectAirport,
              ),
            ],
          ],
      ],
    );
  }
}

class _AirportSectionTitle extends StatelessWidget {
  const _AirportSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AirportChipWrap extends StatelessWidget {
  const _AirportChipWrap({
    required this.airports,
    required this.onSelectAirport,
  });

  final List<Airport> airports;
  final Future<void> Function(Airport airport) onSelectAirport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: airports.map((airport) {
        return SelectionChip(
          label: context.t.createFlight.search.airportNameCode(
            name: airport.nameShort,
            code: airport.displayCode,
          ),
          onPressed: () => onSelectAirport(airport),
        );
      }).toList(),
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
