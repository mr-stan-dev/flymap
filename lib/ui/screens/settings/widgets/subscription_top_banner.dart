import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

class SubscriptionTopBanner extends StatefulWidget {
  const SubscriptionTopBanner({
    required this.state,
    required this.onManage,
    super.key,
  });

  final SubscriptionState state;
  final VoidCallback onManage;

  @override
  State<SubscriptionTopBanner> createState() => _SubscriptionTopBannerState();
}

class _SubscriptionTopBannerState extends State<SubscriptionTopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isPro = state.isPro;
    final cardRadius = BorderRadius.circular(DsRadii.xl);
    final title = isPro ? 'Flymap Pro Active' : 'Flymap Pro';
    final subtitle = switch (state.phase) {
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => 'Checking your subscription status.',
      SubscriptionPhase.pro =>
        'Detailed map mode and unlimited offline articles unlocked.',
      SubscriptionPhase.free =>
        'Unlock detailed maps and unlimited offline articles.',
    };
    final badgeLabel = isPro ? 'PRO ACTIVE' : 'UPGRADE';

    return GestureDetector(
      onTap: widget.onManage,
      child: ClipRRect(
        borderRadius: cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: cardRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPro
                        ? const [
                            Color(0xFF4D3300),
                            Color(0xFF936000),
                            Color(0xFFD59000),
                          ]
                        : const [
                            Color(0xFF13213E),
                            Color(0xFF1D3B69),
                            Color(0xFF2A5E9C),
                          ],
                  ),
                  border: Border.all(
                    color: isPro
                        ? DsBrandColors.proAmber.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalStripesPainter(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -26,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: 124,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _BannerGradientShimmer(value: _controller.value);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BannerBadge(label: badgeLabel),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerBadge extends StatelessWidget {
  const _BannerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DsRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _BannerGradientShimmer extends StatelessWidget {
  const _BannerGradientShimmer({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final center = -0.4 + (value * 1.8);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.11),
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: [
            (center - 0.14).clamp(0.0, 1.0),
            (center - 0.05).clamp(0.0, 1.0),
            center.clamp(0.0, 1.0),
            (center + 0.05).clamp(0.0, 1.0),
            (center + 0.14).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  const _DiagonalStripesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const spacing = 14.0;
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
