import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports_step_content.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports_step_meta.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';

class FlightSearchByAirports extends StatefulWidget {
  const FlightSearchByAirports({super.key});

  @override
  State<FlightSearchByAirports> createState() => _FlightSearchByAirportsState();
}

class _FlightSearchByAirportsState extends State<FlightSearchByAirports> {
  final TextEditingController _searchController = TextEditingController();
  int _previousStepIndex = 0;
  double _stepEnterFrom = 0.0;
  bool _showDownloadSuccess = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlightSearchScreenCubit, FlightSearchScreenState>(
      listenWhen: (previous, current) {
        return previous.errorMessage != current.errorMessage ||
            previous.downloadErrorMessage != current.downloadErrorMessage ||
            previous.downloadDone != current.downloadDone ||
            previous.searchQuery != current.searchQuery ||
            previous.step != current.step;
      },
      listener: (listenerContext, state) {
        final nextStepIndex = FlightSearchStepMeta.indexForStep(state.step);
        if (nextStepIndex != _previousStepIndex) {
          setState(() {
            _stepEnterFrom = nextStepIndex > _previousStepIndex ? 1.0 : -1.0;
            _previousStepIndex = nextStepIndex;
          });
        }

        if (_searchController.text != state.searchQuery) {
          _searchController.value = TextEditingValue(
            text: state.searchQuery,
            selection: TextSelection.collapsed(
              offset: state.searchQuery.length,
            ),
          );
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.downloadErrorMessage != null &&
            state.downloadErrorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.downloadErrorMessage!)));
        }

        if (state.downloadDone) {
          setState(() {
            _showDownloadSuccess = true;
          });
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            homeRefreshNotifier.value = true;
            AppRouter.goHome(this.context);
          });
        }
      },
      builder: (context, state) {
        final cubit = context.read<FlightSearchScreenCubit>();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldPop = await cubit.handleBackAction();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _onBackPressed(context),
              ),
              title: Text(FlightSearchStepMeta.titleForStep(state.step)),
            ),
            body: TweenAnimationBuilder<double>(
              key: ValueKey(state.step.name),
              tween: Tween<double>(begin: _stepEnterFrom, end: 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value * MediaQuery.sizeOf(context).width, 0),
                  child: child,
                );
              },
              child: FlightSearchByAirportsStepContent(
                state: state,
                searchController: _searchController,
                showDownloadSuccess: _showDownloadSuccess,
                onSearchChanged: cubit.searchAirports,
                onClearSearch: () {
                  _searchController.clear();
                  cubit.searchAirports('');
                },
                onToggleFavoriteForSelected:
                    cubit.toggleFavoriteForSelectedAirport,
                onClearSelectedAirport: () {
                  _searchController.clear();
                  cubit.clearSelectedAirportForCurrentStep();
                },
                onSelectAirport: cubit.selectAirport,
                onToggleFavoriteForAirport: cubit.toggleFavoriteForAirport,
                onContinueFromAirportStep: cubit.continueFromAirportStep,
                onContinueFromMap: cubit.continueFromMap,
                onContinueFromOverview: cubit.continueFromOverview,
                onToggleWikiArticle: cubit.toggleWikiArticleSelection,
                onToggleAllWikiArticles: cubit.toggleAllWikiArticleSelections,
                onStartDownload: cubit.startDownload,
                onCancelDownload: cubit.cancelDownload,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onBackPressed(BuildContext context) async {
    final shouldPop = await context
        .read<FlightSearchScreenCubit>()
        .handleBackAction();
    if (shouldPop && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
