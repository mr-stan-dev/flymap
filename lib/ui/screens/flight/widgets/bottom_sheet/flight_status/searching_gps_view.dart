import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_active.dart';

class SearchingGpsView extends StatelessWidget {

  const SearchingGpsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Icon(Icons.gps_fixed, color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'Acquiring GPS Signal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we establish a GPS connection...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}
