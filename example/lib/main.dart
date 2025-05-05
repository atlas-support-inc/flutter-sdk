// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'models/product.dart';
import 'services/wordpress_service.dart';
import 'screens/product_details_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/settings_screen.dart';

const _appId = String.fromEnvironment('ATLAS_APP_ID', defaultValue: '7wukb9ywp9');

void main() {
  runApp(const MyApp());

  AtlasSDK.setAppId(_appId);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Atlas FlutterSDK',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const _MyHomePage(title: 'Kokiri'),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> with TickerProviderStateMixin {
  Function? _dispose;

  int _unreadCount = 0;
  final _wordPressService = WordPressService();
  final List<Product> _products = [];
  final List<Product> _cartItems = [];

  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);

    // Log all Atlas errors

    var disposeErrorHandler = AtlasSDK.onError((error) {
      print("onError(${error.message}${error.original != null ? ', ${error.original}' : ''})");
    });

    // Track conversations stats

    var disposeStatsHandler = AtlasSDK.watchStats((stats) {
      setState(() {
        _unreadCount = stats.conversations.fold(0, (sum, conversation) => sum + conversation.unread);
      });
    });

    // Watch for new conversations

    var disposeChatStartedHandler = AtlasSDK.onChatStarted((chatStarted) {
      print(
          "onChatStarted(ticketId: ${chatStarted.ticketId}${chatStarted.chatbotKey != null ? ', chatbotKey: ${chatStarted.chatbotKey}' : ''})");
    });
    var disposeNewTicketHandler = AtlasSDK.onNewTicket((newTicket) {
      print(
          "onNewTicket(ticketId: ${newTicket.ticketId}${newTicket.chatbotKey != null ? ', chatbotKey: ${newTicket.chatbotKey}' : ''})");
    });

    var disposeNewTicket = AtlasSDK.onNewTicket((ticket) {
      print("🎫 ${ticket.ticketId}");
    });

    _dispose = () {
      disposeNewTicket();
      disposeErrorHandler();
      disposeStatsHandler();
      disposeChatStartedHandler();
      disposeNewTicketHandler();
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _dispose?.call();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMoreProducts) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newProducts = await _wordPressService.getProducts(page: _currentPage);

      setState(() {
        _products.addAll(newProducts.map((data) => Product.fromJson(data)));
        _currentPage++;
        _hasMoreProducts = _currentPage <= _wordPressService.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _error = null;
    });
    await _loadProducts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadProducts();
    }
  }

  void _updateCartItem(Product product) {
    setState(() {
      final existingProduct = _cartItems.firstWhere(
        (item) => item.id == product.id,
        orElse: () => product,
      );

      if (!_cartItems.contains(existingProduct)) {
        _cartItems.add(existingProduct);
      } else {
        // If the product is already in cart, increase its quantity
        existingProduct.quantity += product.quantity;
      }
      _tabController.animateTo(1);
    });
  }

  void _updateCartItemQuantity(Product product, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeWhere((item) => item.id == product.id);
        product.quantity = 0;
      } else {
        product.quantity = quantity;
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == product.id);
      product.quantity = 0;
    });
  }

  Widget _buildProductCard(Product product) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                productId: product.id,
                onCartUpdated: _updateCartItem,
              ),
            ),
          );
        },
        child: ListTile(
          leading: product.imageUrl.isNotEmpty
              ? SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image),
                ),
          title: Text(product.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}'),
                  const SizedBox(width: 8),
                  Text(
                    product.isInStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      color: product.isInStock ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.shopping_basket), text: 'Store'),
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: _cartItems.isEmpty ? 'Cart' : 'Cart (${_cartItems.fold(0, (sum, item) => sum + item.quantity)})',
            ),
            Tab(
              icon: const Icon(Icons.help),
              text: _unreadCount > 0 ? 'Help ($_unreadCount)' : 'Help',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Store screen
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _retryLoading,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: _products.isEmpty && _error == null
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _products.length + (_hasMoreProducts ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _products.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return _buildProductCard(_products[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Cart screen
          SafeArea(
            child: CartScreen(
              cartItems: _cartItems,
              onQuantityChanged: _updateCartItemQuantity,
              onRemoveItem: _removeFromCart,
            ),
          ),
          // Help screen
          SafeArea(
            child: AtlasSDK.Widget(
              persist: "main-chat",
            ),
          ),
        ],
      ),
    );
  }
}
