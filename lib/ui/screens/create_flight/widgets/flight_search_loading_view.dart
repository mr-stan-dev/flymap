import 'dart:async';

import 'package:flutter/material.dart';

/// Loading state for FR24 flight lookups: pulsing skeletons shaped like the
/// result cards, plus a status line that advances through [stages] so the
/// several-second provider round-trip (with retries) feels alive.
class FlightSearchLoadingView extends StatefulWidget {
  const FlightSearchLoadingView({
    required this.stages,
    this.cardCount = 3,
    super.key,
  });

  final List<String> stages;
  final int cardCount;

  static const Duration stageInterval = Duration(milliseconds: 2600);

  @override
  State<FlightSearchLoadingView> createState() =>
      _FlightSearchLoadingViewState();
}

class _FlightSearchLoadingViewState extends State<FlightSearchLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.35,
    upperBound: 0.8,
  )..repeat(reverse: true);

  Timer? _stageTimer;
  int _stageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.stages.length > 1) {
      _stageTimer = Timer.periodic(FlightSearchLoadingView.stageInterval, (_) {
        if (_stageIndex >= widget.stages.length - 1) {
          _stageTimer?.cancel();
          return;
        }
        setState(() => _stageIndex++);
      });
    }
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = widget.stages.isEmpty ? '' : widget.stages[_stageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  stage,
                  key: ValueKey(_stageIndex),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < widget.cardCount; i++) ...[
          _SkeletonCard(pulse: _pulse),
          if (i != widget.cardCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: FadeTransition(
        opacity: pulse,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bone(context, width: 140, height: 16),
                _bone(context, width: 56, height: 22, radius: 8),
              ],
            ),
            const SizedBox(height: 16),
            _bone(context, width: 200, height: 12),
          ],
        ),
      ),
    );
  }

  Widget _bone(
    BuildContext context, {
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
