// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'test_users.dart';

var firstUser = user;
var secondUser = userEmpty;
var currentUser = secondUser;

var appId = 'w51lhvyut7';

class DemoUser {
  final String userId;
  final String atlasId;
  DemoUser(this.userId, this.atlasId);
}

var userAdam = DemoUser('adam', '86427437-8d4e-425c-bae1-109cf7ecbfc5');
var userSara = DemoUser('sara', '4ae4ee1b-5925-4059-9932-16cdf60d5ba9');

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
  AtlasSupportSDK sdk = createAtlasSupportSDK(
    appId: appId,
  );

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

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
        _userIdController.text = identity.atlasId == userAdam.atlasId ? userAdam.userId : identity.atlasId == userSara.atlasId ? userSara.userId : '';
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

    // var disposeChatStartedHandler = AtlasSDK.onChatStarted((ticket) => print("onChatStarted($ticket)"));

    _dispose = () {
      disposeErrorHandler();
      disposeChangeIdentityHandler();
      disposeStatsHandler();
      // disposeChatStartedHandler();
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
                                  // query: "chatbotKey: order",
                                  // persist: "global",
                                  onChatStarted: (data) {
                                    // sdk.updateCustomFields(data['ticketId'], {'test': 'flutter-sourced'});
                                  },
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
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Products list',
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
                  ElevatedButton(
                    onPressed: () {
                      final userId = _userIdController.text;
                      final name = _nameController.text;
                      final email = _emailController.text;
                      final phoneNumber = _phoneNumberController.text;
                      AtlasSDK.identify(
                        userId: userId,
                        name: name.trim() != "" ? name : null,
                        email: email.trim() != "" ? email : null,
                        phoneNumber: phoneNumber.trim() != "" ? phoneNumber : null,
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
