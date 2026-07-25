import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/widgets/airport_category_section.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/widgets/search_result_list.dart';

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
    final hasQuery = _controller.text.trim().isNotEmpty;

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
        // A selected airport fills the field with its label and clears the
        // search results — without this branch that state would fall through
        // to the "no airports found" message below.
        if (widget.selectedAirport != null)
          const SizedBox.shrink()
        else if (widget.isSearchLoading)
          const Center(child: CircularProgressIndicator())
        else if (hasQuery)
          if (widget.results.isNotEmpty)
            SearchResultList(
              airports: widget.results,
              searchQuery: _controller.text.trim(),
              onSelectAirport: widget.onSelectAirport,
            )
          else
            Text(
              context.t.onboarding.noHomeAirportFound,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
        else
          AirportCategorySection(
            title: context.t.createFlight.search.popularAirports,
            airports: widget.popular,
            onSelectAirport: widget.onSelectAirport,
          ),
      ],
    );
  }
}
