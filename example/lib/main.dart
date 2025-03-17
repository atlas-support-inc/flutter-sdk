// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

var appId = 'w51lhvyut7';

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

class Product {
  final String id;
  final String name;
  final double price;
  final Color color;
  final String emoji;
  bool inCart;

  Product(this.id, this.name, this.price, this.color, this.emoji, {this.inCart = false});
}

final List<Product> products = [
  Product(
    '1',
    'Magic Sword',
    299.99,
    const Color(0xFFFF6B6B),
    '⚔️',
  ),
  Product(
    '2',
    'Shield of Protection',
    199.99,
    const Color(0xFF4ECDC4),
    '🛡️',
  ),
  Product(
    '3',
    'Health Potion',
    49.99,
    const Color(0xFF45B7D1),
    '🧪',
  ),
];

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

class _MyHomePageState extends State<MyHomePage> {
  int _unreadCount = 0;
  Function? _dispose;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();

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
      final selectedProducts = products
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
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                            height: MediaQuery.of(context).size.height * 0.82, // Adjusted height
                            child: SafeArea(
                              child: Scaffold(
                                body: AtlasSDK.Widget(
                                  persist: "global",
                                  // query: "chatbotKey: order",
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }))
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_basket), text: 'Store'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Store screen
            Padding(
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          child: ListTile(
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: product.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  product.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            title: Text(product.name),
                            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                            trailing: Switch(
                              value: product.inCart,
                              onChanged: (bool value) {
                                setState(() {
                                  product.inCart = value;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Profile screen
            Padding(
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
          ],
        ),
      ),
    );
  }
}
