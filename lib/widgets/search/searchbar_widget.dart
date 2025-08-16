import 'package:flutter/material.dart';
import 'dart:async';

class SearchbarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String? initialValue;

  const SearchbarWidget({
    super.key, 
    required this.onSearchChanged,
    this.initialValue,
  });

  @override
  State<SearchbarWidget> createState() => _SearchbarWidgetState();
}

class _SearchbarWidgetState extends State<SearchbarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _isSearching = widget.initialValue!.isNotEmpty;
    }
    
    _controller.addListener(() {
      setState(() {
        _isSearching = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print("Searchbar input (debounced): '$value'"); // Debug log
      widget.onSearchChanged(value.trim());
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debounceTimer?.cancel();
    print("Search cleared"); // Debug log
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade200,
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search_sharp, color: Colors.green, size: 28),
          suffixIcon: _isSearching
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
    );
  }
}