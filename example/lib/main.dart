// ignore_for_file: avoid_print

import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'test_users.dart';

var firstUser = user;
var secondUser = userEmpty;
var currentUser = secondUser;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  int _unreadCount = 0;
  Function? _unsubscribe;
  AtlasSupportSDK sdk = createAtlasSupportSDK(
    appId: appId,
    userId: currentUser['id'],
    userHash: currentUser['hash'],
    onError: (error) => print("onError($error)"),
    onNewTicket: (data) => print("onNewTicket($data)"),
    onChangeIdentity: (identity) => print("onChangeIdentity($identity)"),
  );

  @override
  void initState() {
    super.initState();
    _unsubscribe = sdk.watchStats((stats) {
      setState(() {
        _unreadCount = stats.conversations
            .fold(0, (sum, conversation) => sum + conversation.unread);
      });
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: <Widget>[
        badges.Badge(
            showBadge: _unreadCount > 0,
            badgeContent: Text(_unreadCount.toString()),
            position: badges.BadgePosition.topEnd(top: 5, end: 5),
            child: IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Help'),
                        actions: <Widget>[
                          IconButton(
                              onPressed: () {
                                currentUser = currentUser == firstUser
                                    ? secondUser
                                    : firstUser;
                                sdk.identify(
                                    userId: currentUser['id'],
                                    userHash: currentUser['hash']);
                              },
                              icon: const Icon(Icons.refresh))
                        ],
                      ),
                      body: sdk.Widget(
                        persist: "main",
                        query: "chatbotKey: embed_test",
                        onNewTicket: (data) {
                          sdk.updateCustomFields(
                              data['ticketId'], {'test': 'flutter-sourced'});
                        },
                      ),
                    );
                  }));
                }))
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
