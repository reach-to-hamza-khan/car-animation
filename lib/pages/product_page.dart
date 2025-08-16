import 'package:flutter/material.dart';
import 'package:odoo_apk/pages/store_location_select_page.dart';
import 'package:odoo_apk/constants/constants.dart';
import 'package:odoo_apk/widgets/filter_sort_widget.dart';
import 'package:odoo_apk/widgets/search/searchbar_widget.dart';
import 'package:odoo_apk/widgets/sidebar_widget.dart';
import 'package:odoo_apk/widgets/toggle_filter_widget.dart';
import 'package:odoo_apk/widgets/toggle_view_widget.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'product_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool isGridView = false;
  String? selectedCategory;
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.loadProducts().then((_) {
        if (provider.categories.contains("All")) {
          setState(() => selectedCategory = "All");
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.loadProducts();
    setState(() {
      selectedCategory = "All";
      _isSearching = false;
    });
  }

  void _onSearchChanged(String query) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isEmpty) {
      await provider.clearSearch();
    } else {
      await provider.searchProducts(query);
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    // Only apply category filter if not searching
    if (_isSearching) {
      return products; // Return search results as-is
    }
    
    if (selectedCategory == null || selectedCategory == "All") {
      return products;
    }
    return products.where((p) => p.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration:
              BoxDecoration(gradient: Constants.appbarGradient(context)),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return StoreLocationSelectPage();
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            padding: EdgeInsets.all(5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.store,
                    color: Colors.green.shade900), // Location icon
                SizedBox(width: 5),
                Text(
                  "Mumbai",
                  style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Icon(Icons.arrow_drop_down_sharp,
                    color: Colors.green.shade900), // Location icon
              ],
            ),
          ),
        ),
        centerTitle: true,
        titleTextStyle: TextStyle(),
        // elevation: 0,
        leading: Builder(
          builder: (context) {
            return Row(
              children: [
                SizedBox(
                  width: 5,
                ),
                IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    // style: IconButton.styleFrom(
                    //   backgroundColor: Colors.green,
                    // ),
                    icon: Icon(Icons.menu),
                    color: Colors.green.shade900),
              ],
            );
          },
        ),
        actions: [
          ToggleFilterWidget(
            onToggle: (value) {
              print("value: $value");
            },
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      drawer: SidebarWidget(),
      body: Column(
        children: [
          // Search and View Toggle Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterSortWidget(
                  onFilter: () {}, // Now handled internally by FilterSortWidget
                  onSort: () {}, // Now handled internally by FilterSortWidget
                ),
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      return SearchbarWidget(
                        onSearchChanged: _onSearchChanged,
                        initialValue: provider.currentSearchQuery,
                      );
                    },
                  ),
                ),
                ToggleViewWidget(
                  isGridView: isGridView,
                  onToggle: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                ),
              ],
            ),
          ),

          // Category Chips (Hide when searching)
          Consumer<ProductProvider>(
            builder: (ctx, provider, _) {
              if (provider.categories.isEmpty || _isSearching) {
                return SizedBox.shrink();
              }

              return Container(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        selectedColor: Colors.green.shade700,
                        labelStyle: TextStyle(
                          color: selectedCategory == category
                              ? Colors.white
                              : Colors.grey.shade800,
                        ),
                        onSelected: (selected) {
                          setState(() => selectedCategory = category);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Search Results Indicator
          Consumer<ProductProvider>(
            builder: (ctx, provider, _) {
              if (_isSearching && provider.currentSearchQuery.isNotEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: Colors.grey.shade600),
                      SizedBox(width: 8),
                      Text(
                        'Search results for "${provider.currentSearchQuery}"',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${provider.products.length} found',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: Consumer<ProductProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) return _buildLoadingState();
                  if (provider.error.isNotEmpty)
                    return _buildErrorState(provider.error);

                  final filteredProducts = _filterProducts(provider.products);
                  if (filteredProducts.isEmpty) return _buildEmptyState();

                  return isGridView
                      ? GridView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(10),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (ctx, i) => AnimatedProductCard(
                            product: filteredProducts[i],
                            isGridView: true,
                            index: i,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (ctx, i) => AnimatedProductCard(
                            product: filteredProducts[i],
                            isGridView: false,
                            index: i,
                          ),
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
          ),
          SizedBox(height: 16),
          Text(
            _isSearching ? 'Searching products...' : 'Loading products...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            _isSearching ? 'No products found' : 'No products available',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try searching with different keywords'
                : 'Try selecting a different category or refresh',
            style: GoogleFonts.lato(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isSearching) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final provider = Provider.of<ProductProvider>(context, listen: false);
                await provider.clearSearch();
                setState(() {
                  _isSearching = false;
                  selectedCategory = "All";
                });
              },
              child: Text('Show All Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AnimatedProductCard extends StatelessWidget {
  final Product product;
  final bool isGridView;
  final int index;

  const AnimatedProductCard({
    super.key,
    required this.product,
    required this.isGridView,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 500),
      child: AnimatedPadding(
        duration: Duration(milliseconds: 500),
        padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
        child: ProductCard(product: product, isGridView: isGridView),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isGridView;

  const ProductCard(
      {super.key, required this.product, required this.isGridView});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 300),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: Colors.green.shade100,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ProductDetailPage(product: product),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: isGridView ? _buildGridContent() : _buildListContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return Container(
      padding: EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: '${dotenv.env['API_URL']}${product.imageUrl}',
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildShimmerBox(),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported, size: 30),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics:
                  NeverScrollableScrollPhysics(), // Optional: avoid scroll if not needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${'SKU12345'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),

                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${product.category}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),

                  // ✅ Stock at bottom
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.stock > 0 ? "In Stock" : "Out",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: product.stock > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    return Row( 
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: '${dotenv.env['API_URL']}${product.imageUrl}',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildShimmerBox(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
        SizedBox(width: 12),

        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SKU Number (Hardcoded)
              // Text(
              //   "#SKU12345", // Hardcoded SKU
              //   style: GoogleFonts.lato(
              //     fontSize: 12,
              //     color: Colors.grey.shade600,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // SizedBox(height: 4),

              // Product Name (Heading style)
              Text(
                product.name,
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                "Category: ${product.category}",
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "UOM: ${product.uom}",
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              // Category and UOM in a row
            ],
          ),
        ),

        // Stock Status
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                product.stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.stock > 0 ? "In Stock" : "Out",
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: product.stock > 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }
}