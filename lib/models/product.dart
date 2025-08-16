class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final String category;
  final double rating;
  final String uom;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.category,
    required this.rating,
    required this.uom,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      stock: (json['qty_on_hand'] as num).toInt(),
      category: json['category'] as String? ?? 'Uncategorized',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom'] as String? ?? 'Units',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'qty_on_hand': stock,
      'category': category,
      'rating': rating,
      'uom': uom,
    };
  }
}