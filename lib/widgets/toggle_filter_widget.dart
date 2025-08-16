import 'package:flutter/material.dart';

class ToggleFilterWidget extends StatelessWidget {
  final ValueChanged<bool> onToggle;

  const ToggleFilterWidget({
    super.key,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Toggle filter state
        onToggle(true);
      },
      icon: Icon(Icons.tune, color: Colors.green.shade700),
      tooltip: 'Toggle Filter',
    );
  }
}