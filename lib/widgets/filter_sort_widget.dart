import 'package:flutter/material.dart';

class FilterSortWidget extends StatelessWidget {
  final VoidCallback onFilter;
  final VoidCallback onSort;

  const FilterSortWidget({
    super.key,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onFilter,
          icon: Icon(Icons.filter_list, color: Colors.green.shade700),
          tooltip: 'Filter',
        ),
        IconButton(
          onPressed: onSort,
          icon: Icon(Icons.sort, color: Colors.green.shade700),
          tooltip: 'Sort',
        ),
      ],
    );
  }
}