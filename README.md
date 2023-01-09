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

To use it with Android you may need to ensure that *AndroidManifest.xml* includes `<uses-permission android:name="android.permission.INTERNET" />`

## Usage

Using the widget to add the chat

```dart
import 'package:atlas_support_sdk/atlas_support_widget.dart';

// Use widget:
AtlasSupportWidget(appId: "", userId: "", userHash: "")
```

Listening for stats changes

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
            _unreadCount = stats['conversations']
                .fold(0, (sum, conversation) => sum + conversation['unread']);
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
