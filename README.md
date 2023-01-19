<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Atlas customer support chat widget

## Getting started

To use it with Android you may need to ensure that _AndroidManifest.xml_ includes `<uses-permission android:name="android.permission.INTERNET" />`

## Usage

You can run [sample application](https://github.com/atlas-support-inc/flutter-sdk/blob/master/example) by changing credentials in the [main.dart](https://github.com/atlas-support-inc/flutter-sdk/blob/master/example/lib/main.dart) file.

### Using the widget to add the chat

```dart
import 'package:atlas_support_sdk/atlas_support_widget.dart';

// Use widget:
AtlasSupportWidget(appId: "", userId: "", userHash: "")
```

### Listening for stats changes

Each conversation stat instance contains `id`, `unread` (amount of unread messages), and `closed` flag.

```dart
import 'package:atlas_support_sdk/watch_atlas_support_stats.dart';

// Listen:
class _MyWidgetState extends State<MyWidget> {
  int _unreadCount = 0;
  Function? _unsubscribe = null;

  @override
  void initState() {
    super.initState();
    _unsubscribe = watchAtlasSupportStats(
        appId: "",
        userId: "",
        userHash: "",
        onStatsChange: (stats) {
          setState(() {
            _unreadCount = stats.conversations
                .fold(0, (sum, conversation) => sum + conversation.closed ? 0 : conversation.unread);
          });
        });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  // ...
}
```

### Using instance with shared settings

Using SDK instance you can change user for all widgets and watches by calling `sdk.identify(userId: "", userHash: "")`.

```dart
import 'package:atlas_support_sdk/atlas_support_sdk.dart';

// Listen:
class _MyWidgetState extends State<MyWidget> {
  int _unreadCount = 0;
  Function? _unsubscribe = null;
  AtlasSupportSDK atlasSdk = createAtlasSupportSDK(appId: "", userId: "", userHash: "");

  @override
  void initState() {
    super.initState();
    _unsubscribe = atlasSdk.watchStats((stats) {
      setState(() {
        _unreadCount = stats.conversations
            .fold(0, (sum, conversation) => sum + conversation.closed ? 0 : conversation.unread);
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
    return Scaffold(
      body: atlasSdk.Widget()
    );
  }

  // ...
}
```

When using the widget via SDK instance you can also persist its state to prevent loading Atlas more than once.
Use `persist` property with the unique string value at any place and after the initial load the app will render immediately:

```dart
sdk.Widget(persist: "main")
```
