import 'package:atlas_support_sdk/atlas_support_sdk.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart';

const testAppId = "jbnpaijbo0";
const testUserId = "123";
const testUserHash = "123";

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
      appId: testAppId, userId: testUserId, userHash: testUserHash);

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
        Badge(
            showBadge: _unreadCount > 0,
            badgeContent: Text(_unreadCount.toString()),
            position: BadgePosition.topEnd(top: 5, end: 5),
            child: IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Help'),
                      ),
                      body: sdk.Widget(),
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
              style: Theme.of(context).textTheme.headline4,
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
