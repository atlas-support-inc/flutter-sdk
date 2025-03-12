// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'test_users.dart';

var firstUser = user;
var secondUser = userEmpty;
var currentUser = secondUser;

var appId = 'w51lhvyut7';
var userId = 'adam';

void main() {
  runApp(const MyApp());
  AtlasSDK.setAppId(appId);
  AtlasSDK.identify(userId: 'adam', name: 'Adam Smith', email: 'adam@smith.co', phoneNumber: '+1098765432');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  Function? _unsubscribe;
  AtlasSupportSDK sdk = createAtlasSupportSDK(
    appId: appId,
    userId: currentUser['id'],
    userHash: currentUser['hash'],
    name: 'Jon',
    email: 'jon@atlas.so',
    phoneNumber: '1234567890',
    onError: (error) => print("onError($error)"),
    onNewTicket: (data) => print("onNewTicket($data)"),
    onChangeIdentity: (identity) => print("onChangeIdentity($identity)"),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unsubscribe = sdk.watchStats((stats) {
      setState(() {
        _unreadCount = stats.conversations.fold(0, (sum, conversation) => sum + conversation.unread);
      });
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
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
                        builder: (BuildContext context) {
                          return Container(
                            // decoration: BoxDecoration(
                            //   color: Theme.of(context).scaffoldBackgroundColor,
                            //   borderRadius: const BorderRadius.only(
                            //     topLeft: Radius.circular(20.0),
                            //     topRight: Radius.circular(20.0),
                            //   ),
                            // ),
                            height: MediaQuery.of(context).size.height * 0.86, // Adjusted height
                            child: SafeArea(
                              child: Scaffold(
                                body: AtlasSDK.Widget(
                                  // persist: "main",
                                  // query: "chatbotKey: embed_test",
                                  // onNewTicket: (data) {
                                  //   sdk.updateCustomFields(data['ticketId'], {'test': 'flutter-sourced'});
                                  // },
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
                    child: const Text('Update'),
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
