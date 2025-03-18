class ProductVariation {
  final String id;
  final double price;
  final String stockStatus;

  ProductVariation({
    required this.id,
    required this.price,
    required this.stockStatus,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'].toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockStatus: json['stock'] ?? 'out_of_stock',
    );
  }

  bool get isInStock => stockStatus == 'in_stock';
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double regularPrice;
  final double salePrice;
  final String stockStatus;
  final String imageUrl;
  final List<String> categories;
  final String link;
  final List<ProductVariation> variations;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.stockStatus,
    required this.imageUrl,
    required this.categories,
    required this.link,
    required this.variations,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper function to parse price strings
    double parsePrice(dynamic value) {
      if (value == null || value.toString().isEmpty) return 0.0;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final price = parsePrice(json['price']);
    final regularPrice = parsePrice(json['regular_price']);
    // Only parse sale price if it's not empty
    final salePrice = json['sale_price'].toString().isEmpty ? regularPrice : parsePrice(json['sale_price']);

    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: price,
      regularPrice: regularPrice,
      salePrice: salePrice,
      stockStatus: json['stock_status'] ?? 'out_of_stock',
      imageUrl: json['image'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      link: json['link'] ?? '',
      variations: (json['variations'] as List<dynamic>? ?? [])
          .map((variation) => ProductVariation.fromJson(variation))
          .toList(),
    );
  }

  bool get isInStock => stockStatus == 'in_stock';
  bool get isOnSale => salePrice > 0 && salePrice < regularPrice;
  bool get hasVariations => variations.isNotEmpty;
  bool get inCart => quantity > 0;
  double get totalPrice => price * quantity;
} 