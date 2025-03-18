// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'models/product.dart';
import 'services/wordpress_service.dart';
import 'screens/product_details_screen.dart';
import 'screens/cart_screen.dart';

const appId = String.fromEnvironment('ATLAS_APP_ID', defaultValue: '7wukb9ywp9');

class DemoUser {
  final String atlasId;
  final String userId;
  final String userHash;
  DemoUser(this.atlasId, this.userId, this.userHash);
}

var userAdam = DemoUser(
    '86427437-8d4e-425c-bae1-109cf7ecbfc5', 'adam', '28af9d7e2fe67562e0b3dc0e4df9ae070be4a286f28fed8bd9eb555b68feb399');
var userSara = DemoUser(
    '4ae4ee1b-5925-4059-9932-16cdf60d5ba9', 'sara', 'edceaca5418b1e3bf339af13460236dbae40a335a2d1b8148681adaa2cc5753e');

void main() {
  runApp(const MyApp());

  AtlasSDK.setAppId(appId);
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
      home: const MyHomePage(title: 'Kokiri'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _unreadCount = 0;
  Function? _dispose;
  final _wordPressService = WordPressService();
  final List<Product> _products = [];
  final List<Product> _cartItems = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  final ScrollController _scrollController = ScrollController();
  String? _error;
  late TabController _tabController;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

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

    // Track identity changes

    var atlasId = AtlasSDK.getAtlasId();
    if (atlasId != null) _userIdController.text = atlasId;

    var disposeChangeIdentityHandler = AtlasSDK.onChangeIdentity((identity) {
      if (identity == null) {
        _userIdController.text = '';
        print("onChangeIdentity(null)");
      } else {
        _userIdController.text = identity.atlasId == userAdam.atlasId
            ? userAdam.userId
            : identity.atlasId == userSara.atlasId
                ? userSara.userId
                : '';
        print("onChangeIdentity({atlasId: ${identity.atlasId}})");
      }
    });

    // Track conversations stats

    var disposeStatsHandler = AtlasSDK.watchStats((stats) {
      setState(() {
        _unreadCount = stats.conversations.fold(0, (sum, conversation) => sum + conversation.unread);
      });
    });

    // Watch for new conversations

    var disposeChatStartedHandler = AtlasSDK.onChatStarted((chatStarted) {
      print("onChatStarted($chatStarted)");
      // Get list of products that are in the cart
      final selectedProducts = _products
          .where((product) => product.inCart)
          .map((product) => product.name)
          .toList();
      
      // Update custom fields with selected products
      if (selectedProducts.isNotEmpty) {
        AtlasSDK().updateCustomFields(
          chatStarted.ticketId,
          {'products': selectedProducts},
        );
      }
    });
    var disposeNewTicketHandler = AtlasSDK.onNewTicket((newTicket) => print("onNewTicket($newTicket)"));

    _dispose = () {
      disposeErrorHandler();
      disposeChangeIdentityHandler();
      disposeStatsHandler();
      disposeChatStartedHandler();
      disposeNewTicketHandler();
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dispose?.call();
    _tabController.dispose();
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
          badges.Badge(
              showBadge: _unreadCount > 0,
              badgeContent: Text(_unreadCount.toString()),
              position: badges.BadgePosition.topEnd(top: 5, end: 5),
              child: IconButton(
                  icon: const Icon(Icons.help),
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
                                persist: "global",
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }))
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.shopping_basket), text: 'Store'),
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: _cartItems.isEmpty ? 'Cart' : 'Cart (${_cartItems.fold(0, (sum, item) => sum + item.quantity)})',
            ),
            const Tab(icon: Icon(Icons.person), text: 'Profile'),
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
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
          // Profile screen
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: <Widget>[
                  RadioListTile(
                    title: Text('User ID: "${userAdam.userId}"'),
                    value: userAdam.userId,
                    groupValue: _userIdController.text,
                    onChanged: (value) {
                      setState(() {
                        _userIdController.text = value as String;
                      });
                    },
                  ),
                  RadioListTile(
                    title: Text('User ID: "${userSara.userId}"'),
                    value: userSara.userId,
                    groupValue: _userIdController.text,
                    onChanged: (value) {
                      setState(() {
                        _userIdController.text = value as String;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    controller: _nameController,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    controller: _emailController,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    controller: _phoneNumberController,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    controller: _titleController,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final userId = _userIdController.text;
                      final name = _nameController.text;
                      final email = _emailController.text;
                      final phoneNumber = _phoneNumberController.text;
                      final title = _titleController.text;
                      AtlasSDK.identify(
                        userId: userId,
                        userHash: userId == userAdam.userId ? userAdam.userHash : userId == userSara.userId ? userSara.userHash : null,
                        name: name.trim() != "" ? name : null,
                        email: email.trim() != "" ? email : null,
                        phoneNumber: phoneNumber.trim() != "" ? phoneNumber : null,
                        customFields: {
                          if (title.trim() != "") 'title': title,
                        },
                      );
                    },
                    child: const Text('Identify'),
                  ),
                  const SizedBox(height: 10),
                  const ElevatedButton(
                    onPressed: AtlasSDK.logout,
                    child: Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
