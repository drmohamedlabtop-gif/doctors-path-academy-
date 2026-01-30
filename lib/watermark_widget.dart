import 'package:flutter/material.dart';

class DynamicWatermark extends StatelessWidget {
  final String text;
  const DynamicWatermark({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4), // Increased opacity for better visibility
        ),
      ),
    );
  }
}
