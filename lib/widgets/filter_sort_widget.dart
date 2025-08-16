import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterSortWidget extends StatefulWidget {
  final VoidCallback onFilter;
  final VoidCallback onSort;

  const FilterSortWidget({
    super.key,
    required this.onFilter,
    required this.onSort,
  });

  @override
  State<FilterSortWidget> createState() => _FilterSortWidgetState();
}

class _FilterSortWidgetState extends State<FilterSortWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filter Button
        Container(
          margin: EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _showFilterModal(context),
            icon: Icon(Icons.filter_list, size: 20, color: Colors.green.shade700),
            label: Text(
              'Filter',
              style: TextStyle(color: Colors.green.shade700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        // Sort Button
        Container(
          child: ElevatedButton.icon(
            onPressed: () => _showSortModal(context),
            icon: Icon(Icons.sort, size: 20, color: Colors.green.shade700),
            label: Text(
              'Sort',
              style: TextStyle(color: Colors.green.shade700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterModalContent(),
    );
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SortModalContent(),
    );
  }
}

class FilterModalContent extends StatefulWidget {
  @override
  _FilterModalContentState createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<FilterModalContent> {
  String? selectedCategory;
  bool inStockOnly = false;
  double minPrice = 0;
  double maxPrice = 10000;
  RangeValues priceRange = RangeValues(0, 10000);

  @override
  void initState() {
    super.initState();
    // Initialize with current filter values if any
    priceRange = RangeValues(minPrice, maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
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
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
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
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        selectedColor: Colors.green.shade600,
                        labelStyle: TextStyle(
                          color: selectedCategory == category
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = selected ? category : null;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: 20),

          // Stock Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In Stock Only',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Switch(
                value: inStockOnly,
                onChanged: (value) {
                  setState(() {
                    inStockOnly = value;
                  });
                },
                activeColor: Colors.green.shade600,
              ),
            ],
          ),
          SizedBox(height: 20),

          // Price Range Filter
          Text(
            'Price Range',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '₹${priceRange.start.round()}',
              '₹${priceRange.end.round()}',
            ),
            activeColor: Colors.green.shade600,
            inactiveColor: Colors.green.shade200,
            onChanged: (RangeValues values) {
              setState(() {
                priceRange = values;
                minPrice = values.start;
                maxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${priceRange.start.round()}', 
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600)),
              Text('₹${priceRange.end.round()}', 
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Clear filters
                    setState(() {
                      selectedCategory = null;
                      inStockOnly = false;
                      priceRange = RangeValues(0, 10000);
                      minPrice = 0;
                      maxPrice = 10000;
                    });
                    Provider.of<ProductProvider>(context, listen: false)
                        .clearClientSideFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    Provider.of<ProductProvider>(context, listen: false)
                        .applyClientSideFilter(
                      category: selectedCategory,
                      inStockOnly: inStockOnly,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SortModalContent extends StatefulWidget {
  @override
  _SortModalContentState createState() => _SortModalContentState();
}

class _SortModalContentState extends State<SortModalContent> {
  String? selectedSort;

  final List<Map<String, String>> sortOptions = [
    {'key': 'name_asc', 'label': 'Name (A-Z)'},
    {'key': 'name_desc', 'label': 'Name (Z-A)'},
    {'key': 'price_asc', 'label': 'Price (Low to High)'},
    {'key': 'price_desc', 'label': 'Price (High to Low)'},
    {'key': 'stock_asc', 'label': 'Stock (Low to High)'},
    {'key': 'stock_desc', 'label': 'Stock (High to Low)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort Products',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Sort Options
          ...sortOptions.map((option) => RadioListTile<String>(
            title: Text(
              option['label']!,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            value: option['key']!,
            groupValue: selectedSort,
            activeColor: Colors.green.shade600,
            onChanged: (String? value) {
              setState(() {
                selectedSort = value;
              });
            },
          )).toList(),

          SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedSort != null
                      ? () {
                          Provider.of<ProductProvider>(context, listen: false)
                              .sortProducts(selectedSort!);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text('Apply Sort'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}