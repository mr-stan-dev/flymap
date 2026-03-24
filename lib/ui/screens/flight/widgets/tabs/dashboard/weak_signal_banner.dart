import 'package:flutter/material.dart';

class WeakSignalBanner extends StatelessWidget {
  const WeakSignalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.network_check, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Weak GPS signal. Values may drift until accuracy improves.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
