import 'package:flutter/material.dart';

class ToggleViewWidget extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onToggle;

  const ToggleViewWidget({
    super.key,
    required this.isGridView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isGridView ? Icons.view_list : Icons.grid_view,
        color: Colors.green.shade700,
      ),
      tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
    );
  }
}