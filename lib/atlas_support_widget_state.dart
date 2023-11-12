library atlas_support_sdk;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '_config.dart';
import 'atlas_support_widget.dart';

class AtlasSupportWidgetState extends State<AtlasSupportWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = initController();
  }

  @override
  void didUpdateWidget(AtlasSupportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    var hasChanged = widget.userId != oldWidget.userId ||
        widget.userHash != oldWidget.userHash ||
        widget.userName != oldWidget.userName ||
        widget.userEmail != oldWidget.userEmail;
    if (hasChanged) {
      _loadPage(_controller);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  _loadPage(WebViewController controller) {
    var url = Uri.parse(atlasWidgetBaseUrl).replace(queryParameters: {
      'appId': widget.appId,
      'userId': widget.userId,
      ...widget.userHash == null || widget.userHash == ""
          ? {}
          : {'userHash': widget.userHash},
      ...widget.userName == null || widget.userName == ""
          ? {}
          : {'userName': widget.userName},
      ...widget.userEmail == null || widget.userEmail == ""
          ? {}
          : {'userEmail': widget.userEmail},
    });
    controller.loadRequest(url);
  }

  WebViewController initController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _loadPage(controller);

    controller.addJavaScriptChannel("FlutterWebView",
        onMessageReceived: (package) {
      try {
        final message = (jsonDecode(package.message) as Map<String, dynamic>);
        if (message['type'] == 'atlas:error') {
          widget.onError
              ?.call('AtlasSupportWidget: ${message['errorMessage']}');
        }
      } catch (e) {
        widget.onError?.call('AtlasSupportWidget: ${package.message}');
      }
    });

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }
}
