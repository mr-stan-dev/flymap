import 'package:flutter/material.dart';

class BottomSheetLoading extends StatelessWidget {
  const BottomSheetLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}
