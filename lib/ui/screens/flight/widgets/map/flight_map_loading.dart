import 'package:flutter/material.dart';

class FlightMapLoading extends StatelessWidget {
  const FlightMapLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}
