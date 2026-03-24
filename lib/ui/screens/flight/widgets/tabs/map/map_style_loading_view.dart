import 'package:flutter/material.dart';

class MapStyleLoadingView extends StatelessWidget {
  const MapStyleLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading map style...'),
        ],
      ),
    );
  }
}
