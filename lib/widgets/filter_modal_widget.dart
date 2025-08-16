import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterModalWidget extends StatefulWidget {
  final List<String> categories;
  final Function({
    String? category,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
  }) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterModalWidget({
    super.key,
    required this.categories,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<FilterModalWidget> createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  String? selectedCategory;
  bool inStockOnly = false;
  double? minPrice;
  double? maxPrice;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : null;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onApplyFilters(
      category: selectedCategory,
      inStockOnly: inStockOnly,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = widget.categories.isNotEmpty ? widget.categories.first : null;
      inStockOnly = false;
      minPrice = null;
      maxPrice = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    widget.onClearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Products',
                style: GoogleFonts.lato(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Category Filter
          Text(
            'Category',
            style: GoogleFonts.lato(
              fontSize: 16, 
              fontWeight: FontWeight.w600
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
          ),
          SizedBox(height: 20),

          // Stock Filter
          Row(
            children: [
              Checkbox(
                value: inStockOnly,
                onChanged: (value) {
                  setState(() {
                    inStockOnly = value ?? false;
                  });
                },
                activeColor: Colors.green,
              ),
              Text(
                'In Stock Only',
                style: GoogleFonts.lato(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Price Range Filter
          Text(
            'Price Range',
            style: GoogleFonts.lato(
              fontSize: 16, 
              fontWeight: FontWeight.w600
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '\$',
                  ),
                  onChanged: (value) {
                    minPrice = value.isEmpty ? null : double.tryParse(value);
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '\$',
                  ),
                  onChanged: (value) {
                    maxPrice = value.isEmpty ? null : double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.lato(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.lato(
                      fontSize: 16, 
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}