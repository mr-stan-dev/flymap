import 'package:flutter/material.dart';

class FlightMapTabLoading extends StatelessWidget {
  const FlightMapTabLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
