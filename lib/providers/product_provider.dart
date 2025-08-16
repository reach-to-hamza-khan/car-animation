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
  List<String> _categories = ["All"]; // Initialize with "All"
  bool _isLoading = false;
  String _error = '';
  String? _baseUrl; // Will be loaded from environment
  String _searchQuery = ''; // Add search query field
  List<Product> _filteredProducts = []; // Add filtered products list

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  List<Product> get filteredProducts => _filteredProducts;
  String get searchQuery => _searchQuery;

  // Load base URL from environment
  Future<void> _loadBaseUrl() async {
    // Implement your environment loading logic here
    _baseUrl = 'https://dev-wms.mysamplewebsite.in';
  }

  // Method to search products by name
  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if ('${dotenv.env['API_URL']}' == null) await _loadBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      final warehouseId = prefs.getInt('default_warehouse') ?? 1;

      final Map<String, dynamic> params = {
        "warehouse_id": warehouseId,
      };

      // Add search query if provided
      if (_searchQuery.isNotEmpty) {
        params["product_name"] = _searchQuery;
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
          "params": params
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Request timed out after 10 seconds");
      });

      if (kDebugMode) {
        print("Raw API Response (searchProducts): ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['result'] != null) {
          _parseApiResponse(data['result']);
        } else {
          _error = 'API Error: Invalid response format';
          _products = [];
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        _products = [];
      }
    } catch (e) {
      _error = 'Failed to search products: ${e.toString()}';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    _searchQuery = ''; // Reset search query when loading all products
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if ('${dotenv.env['API_URL']}' == null) await _loadBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      final warehouseId = prefs.getInt('default_warehouse') ?? 1;

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/product'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$sessionId'
        },
        body: json.encode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {"warehouse_id": warehouseId}
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
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        _products = [];
      }
    } catch (e) {
      _error = 'Failed to load products: ${e.toString()}';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to apply client-side filters
  void applyFilters({
    String? category,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
  }) {
    _filteredProducts = List.from(_products);

    // Filter by category
    if (category != null && category != "All") {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == category)
          .toList();
    }

    // Filter by stock
    if (inStockOnly == true) {
      _filteredProducts = _filteredProducts
          .where((product) => product.stock > 0)
          .toList();
    }

    // Filter by price range
    if (minPrice != null) {
      _filteredProducts = _filteredProducts
          .where((product) => product.price >= minPrice)
          .toList();
    }

    if (maxPrice != null) {
      _filteredProducts = _filteredProducts
          .where((product) => product.price <= maxPrice)
          .toList();
    }

    notifyListeners();
  }

  // Method to clear filters
  void clearFilters() {
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Method to get filtered products for a specific category
  List<Product> getProductsByCategory(String category) {
    if (category == "All") {
      return _filteredProducts.isNotEmpty ? _filteredProducts : _products;
    }
    return (_filteredProducts.isNotEmpty ? _filteredProducts : _products)
        .where((product) => product.category == category)
        .toList();
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
    _filteredProducts = List.from(_products); // Initialize filtered products
  }

  Future<Product> fetchProductDetails(int productId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (_baseUrl == null) await _loadBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');
      final warehouseId = prefs.getInt('default_warehouse') ?? 1;

      final response = await http.post(
        Uri.parse('$_baseUrl/product'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$sessionId'
        },
        body: json.encode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "warehouse_id": warehouseId,
            "product_id": productId
          }
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Request timed out after 10 seconds");
      });

      if (kDebugMode) {
        print("Raw API Response (fetchProductDetails): ${response.body}");
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          
          // Create category map
          final Map<int, String> categoryMap = {};
          for (var cat in result['categories'] as List) {
            categoryMap[cat['id']] = cat['name'] as String;
          }

          final productsByCategory = result['products_by_categ'] as Map<String, dynamic>;
          
          for (var category in productsByCategory.values) {
            for (var product in category as List) {
              final variants = product['variants'] as List;
              final categoryId = product['categ_id'] as int;
              final categoryName = categoryMap[categoryId] ?? 'Uncategorized';

              for (var variant in variants) {
                if (variant['id'] == productId) {
                  return Product(
                    id: variant['id'],
                    // Use template name instead of variant name
                    name: product['name'] as String,
                    description: product['description'] ?? '',
                    price: (variant['price'] as num).toDouble(),
                    imageUrl: variant['image_url'] ?? product['image_url'],
                    stock: (variant['qty_on_hand'] as num).toInt(),
                    category: categoryName,
                    rating: 0.0,
                    uom: variant['uom'] ?? 'Units',
                  );
                }
              }
            }
          }
          throw Exception("Product not found in response");
        } else {
          _error = 'API Error: ${data['message'] ?? 'Invalid response format'}';
          throw Exception(_error);
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode} - ${response.body}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Failed to load product details: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    _filteredProducts.insert(0, product);
    notifyListeners();
  }
}