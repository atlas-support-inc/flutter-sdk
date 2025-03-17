library atlas_support_sdk;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'atlas_support_widget.dart';
import '_config.dart';
import '_get_package_version.dart';

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
    var hasChanged = widget.appId != oldWidget.appId ||
        widget.userId != oldWidget.userId ||
        widget.userHash != oldWidget.userHash ||
        widget.query != oldWidget.query;
    if (hasChanged) {
      _loadPage(_controller);
    }
  }

  @override
  void dispose() {
    _controller.clearCache();
    _controller.setJavaScriptMode(JavaScriptMode.disabled);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  _loadPage(WebViewController controller) async {
    var url = Uri.parse(atlasWidgetBaseUrl).replace(queryParameters: {
      'sdkVersion': 'flutter@${await getPackageVersion()}',
      'appId': widget.appId,
      ...widget.query == null || widget.query == "" ? {} : {'query': widget.query!.replaceAll(RegExp(r'\s'), '')},
      ...widget.userId == null || widget.userId == "" ? {} : {'userId': widget.userId},
      ...widget.userHash == null || widget.userHash == "" ? {} : {'userHash': widget.userHash},
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

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _loadPage(controller);

    controller.addJavaScriptChannel("FlutterWebView", onMessageReceived: (package) {
      try {
        final message = (jsonDecode(package.message) as Map<String, dynamic>);
        if (message['type'] == 'atlas:error') {
          widget.onError?.call('AtlasSupportWidget: ${message['errorMessage']}');
        } else if (message['type'] == 'atlas:chatStarted') {
          widget.onChatStarted?.call({'ticketId': message['ticketId'], 'chatbotKey': message['chatbotKey']});
        } else if (message['type'] == 'atlas:newTicket') {
          widget.onNewTicket?.call({'ticketId': message['ticketId'], 'chatbotKey': message['chatbotKey']});
        } else if (message['type'] == 'atlas:changeIdentity') {
          widget.onChangeIdentity?.call({'atlasId': message['atlasId']});
        }
      } catch (e) {
        widget.onError?.call('AtlasSupportWidget: ${package.message}');
      }
    });

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }
}
