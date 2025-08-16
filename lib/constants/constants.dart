import 'package:flutter/material.dart';

class Constants {
  static BoxDecoration appbarGradient(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.shade50,
          Colors.green.shade100,
        ],
      ),
    );
  }
}