import 'package:flutter/material.dart';
import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import '../models/product.dart';
import '../services/wordpress_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final Function(Product product)? onCartUpdated;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.onCartUpdated,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<Product> _productFuture;
  final _wordPressService = WordPressService();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProductDetails();
  }

  Future<Product> _loadProductDetails() async {
    final productData = await _wordPressService.getProductDetails(widget.productId);
    return Product.fromJson(productData);
  }

  Widget _buildPriceInfo(Product product) {
    if (product.isOnSale) {
      return Row(
        children: [
          Text(
            '\$${product.salePrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${product.regularPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
          ),
        ],
      );
    } else {
      return Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
      );
    }
  }

  Widget _buildQuantityControls(Product product) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove),
            color: _quantity > 1 ? Theme.of(context).primaryColor : Colors.grey,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              _quantity.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(Product product) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: product.isInStock
            ? () {
                setState(() {
                  product.quantity = _quantity;
                  widget.onCartUpdated?.call(product);
                });
                Navigator.pop(context);
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          product.isInStock ? 'Add to Cart - \$${(product.price * _quantity).toStringAsFixed(2)}' : 'Out of Stock',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SafeArea(
        child: FutureBuilder<Product>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _productFuture = _loadProductDetails();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final product = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.categories.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: product.categories.map((category) {
                              return Chip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                backgroundColor: Colors.grey[100],
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        _buildPriceInfo(product),
                        if (product.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (product.isInStock) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Quantity',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _buildQuantityControls(product),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildAddToCartButton(product),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                enableDrag: false,
                                showDragHandle: true,
                                builder: (BuildContext context) {
                                  return SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.82,
                                    child: SafeArea(
                                      child: Scaffold(
                                        body: AtlasSDK.Widget(
                                          query: "chatbotKey: product_details; prefer: new",
                                          onNewTicket: (chatStarted) {
                                            AtlasSDK.updateCustomFields(
                                              chatStarted.ticketId,
                                              {
                                                'product_link': {'url': product.link, 'title': product.name}
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Ask About This Product',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
