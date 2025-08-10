import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/airport.dart';
import '../viewmodel/flight_search_screen_cubit.dart';
import '../viewmodel/flight_search_screen_state.dart';

class AirportAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Function(Airport) onAirportSelected;
  final Function() onAirportClear;
  final Airport? initialAirport;
  final FlightSearchScreenCubit cubit;

  const AirportAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onAirportSelected,
    required this.onAirportClear,
    required this.cubit,
    this.initialAirport,
  });

  @override
  State<AirportAutocompleteField> createState() =>
      _AirportAutocompleteFieldState();
}

class _AirportAutocompleteFieldState extends State<AirportAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.initialAirport != null) {
      _controller.text =
          '${widget.initialAirport!.airportName} (${widget.initialAirport!.code})';
    }

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightSearchScreenCubit, FlightSearchScreenState>(
      bloc: widget.cubit,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: context.textTheme.body16Medium),
            const SizedBox(height: 8),
            Autocomplete<Airport>(
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return StatefulBuilder(
                      builder: (context, setTextFieldState) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            prefixIcon: Icon(
                              widget.icon,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: textEditingController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                      widget.onAirportClear();
                                      setTextFieldState(() {});
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              widget.cubit.searchAirports(value);
                            } else {
                              widget.onAirportClear();
                            }
                            // Trigger rebuild to update clear button visibility
                            setTextFieldState(() {});
                          },
                        );
                      },
                    );
                  },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Airport>.empty();
                }

                // Get the current state from the cubit
                final state = widget.cubit.state;

                if (state is AirportSearchResults) {
                  return state.airports;
                }

                return const Iterable<Airport>.empty();
              },
              displayStringForOption: (Airport airport) {
                return '${airport.airportName} (${airport.code}) - ${airport.city}, ${airport.countryCode}';
              },
              onSelected: (Airport airport) {
                _controller.text = '${airport.airportName} (${airport.code})';
                widget.onAirportSelected(airport);
              },
              optionsViewBuilder: (context, onSelected, options) {
                if (state is AirportSearchLoading) {
                  return const Material(
                    elevation: 4,
                    child: ListTile(
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Searching airports...'),
                    ),
                  );
                }

                if (state is AirportSearchResults) {
                  return Material(
                    elevation: 4,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: state.airports.length.clamp(0, 10),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final airport = state.airports[index];
                        return ListTile(
                          title: Text(
                            '${airport.airportName} (${airport.code})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${airport.city}, ${airport.countryCode}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          onTap: () {
                            onSelected(airport);
                          },
                        );
                      },
                    ),
                  );
                }

                if (state is AirportSearchNoResults) {
                  return const Material(
                    elevation: 4,
                    child: ListTile(
                      title: Text('No airports found'),
                      subtitle: Text('Try a different search term'),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}
