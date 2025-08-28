import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/home_tab_loaded.dart';

// Global refresh notifier that can be accessed from anywhere
final ValueNotifier<bool> homeRefreshNotifier = ValueNotifier(false);

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeTabCubit(),
      child: _HomeTabContent(),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final _logger = Logger('HomeTabContent');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: homeRefreshNotifier,
      builder: (context, shouldRefresh, child) {
        // Trigger refresh when notifier value becomes true
        if (shouldRefresh) {
          _logger.log('HomeTab: Refresh triggered by ValueNotifier');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HomeTabCubit>().refresh();
            // Reset the notifier after triggering refresh
            homeRefreshNotifier.value = false;
          });
        }

        return BlocBuilder<HomeTabCubit, HomeTabState>(
          builder: (context, state) {
            switch (state) {
              case HomeTabLoading():
                return Center(child: CircularProgressIndicator());
              case HomeTabSuccess():
                return HomeTabLoaded(state);
              case HomeTabError():
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load flights',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () => context.read<HomeTabCubit>().retry(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
            }
          },
        );
      },
    );
  }
}
