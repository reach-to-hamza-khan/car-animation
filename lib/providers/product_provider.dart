import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odoo_apk/services/user/user_storage_service.dart'
    as UserStorageService;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _allProducts = []; // Store all products for client-side filtering
  List<String> _categories = ["All"]; // Initialize with "All"
  bool _isLoading = false;
  String _error = '';
  String? _baseUrl; // Will be loaded from environment
  String _currentSearchQuery = ''; // Track current search query

  List<Product> get products => _products;
  List<Product> get allProducts => _allProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get currentSearchQuery => _currentSearchQuery;

  // Load base URL from environment
  Future<void> _loadBaseUrl() async {
    // Implement your environment loading logic here
    _baseUrl = 'https://dev-wms.mysamplewebsite.in';
  }

  Future<void> loadProducts({String? searchQuery}) async {
    _isLoading = true;
    _error = '';
    _currentSearchQuery = searchQuery ?? '';
    notifyListeners();

    try {
      if ('${dotenv.env['API_URL']}' == null) await _loadBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      final warehouseId = prefs.getInt('default_warehouse') ?? 1;

      // Prepare request body with optional search parameter
      final Map<String, dynamic> requestParams = {
        "warehouse_id": warehouseId,
      };
      
      // Add search parameter if provided
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        requestParams["product_name"] = searchQuery.trim();
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/product'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$sessionId'
        },
        body: json.encode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": requestParams
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Request timed out after 10 seconds");
      });

      if (kDebugMode) {
        print("Raw API Response (loadProducts): ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['result'] != null) {
          _parseApiResponse(data['result']);
        } else {
          _error = 'API Error: Invalid response format';
          _products = [];
          _allProducts = [];
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        _products = [];
        _allProducts = [];
      }
    } catch (e) {
      _error = 'Failed to load products: ${e.toString()}';
      _products = [];
      _allProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Server-side search method
  Future<void> searchProducts(String query) async {
    await loadProducts(searchQuery: query);
  }

  // Clear search and load all products
  Future<void> clearSearch() async {
    await loadProducts();
  }

  void _parseApiResponse(Map<String, dynamic> result) {
    // Create category map
    final Map<int, String> categoryMap = {};
    for (var cat in result['categories'] as List) {
      categoryMap[cat['id']] = cat['name'] as String;
    }

    // Update categories list
    _categories = ["All"]..addAll(categoryMap.values.toSet().toList());

    // Parse products
    final productsByCategory = result['products_by_categ'] as Map<String, dynamic>;
    final List<Product> allProducts = [];

    productsByCategory.forEach((categoryId, categoryProducts) {
      for (var product in categoryProducts as List) {
        final variants = product['variants'] as List;
        final categoryId = product['categ_id'] as int;
        final categoryName = categoryMap[categoryId] ?? 'Uncategorized';

        for (var variant in variants) {
          allProducts.add(Product(
            id: variant['id'],
            name: product['name'] as String, 
            description: product['description'] ?? '',
            price: (variant['price'] as num).toDouble(),
            imageUrl: variant['image_url'] ?? product['image_url'],
            stock: (variant['qty_on_hand'] as num).toInt(),
            category: categoryName, // Use mapped category name
            rating: 0.0,
            uom: variant['uom'] ?? 'Units',
          ));
        }
      }
    });

    _products = allProducts;
    _allProducts = List.from(allProducts); // Store copy for client-side filtering
  }

  // Client-side filtering methods
  void applyClientSideFilter({
    String? category,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
  }) {
    List<Product> filteredProducts = List.from(_allProducts);

    // Filter by category
    if (category != null && category != "All" && category.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((product) => product.category == category)
          .toList();
    }

    // Filter by stock availability
    if (inStockOnly == true) {
      filteredProducts = filteredProducts
          .where((product) => product.stock > 0)
          .toList();
    }

    // Filter by price range
    if (minPrice != null) {
      filteredProducts = filteredProducts
          .where((product) => product.price >= minPrice)
          .toList();
    }

    if (maxPrice != null) {
      filteredProducts = filteredProducts
          .where((product) => product.price <= maxPrice)
          .toList();
    }

    _products = filteredProducts;
    notifyListeners();
  }

  // Reset client-side filters
  void clearClientSideFilters() {
    _products = List.from(_allProducts);
    notifyListeners();
  }

  // Sort products
  void sortProducts(String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        _products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        _products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        _products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_asc':
        _products.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        _products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }
    notifyListeners();
  }
}