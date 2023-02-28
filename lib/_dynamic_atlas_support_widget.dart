library atlas_support_sdk;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '_dynamic_atlas_support_widget_state.dart';
import 'atlas_support_widget.dart';

class DynamicAtlasSupportWidget extends StatefulWidget {
  final String appId;
  final String? initialUserId;
  final String? initialUserHash;
  final String? initialUserName;
  final String? initialUserEmail;
  final Function changeIdentityNotifier;
  final AtlasWidgetErrorHandler? onError;
  final WebViewController? controller;
  final Function(WebViewController controller)? onNewController;

  const DynamicAtlasSupportWidget(
      {Key? key,
      required this.appId,
      this.initialUserId,
      this.initialUserHash,
      this.initialUserName,
      this.initialUserEmail,
      this.onError,
      this.controller,
      required this.onNewController,
      required this.changeIdentityNotifier})
      : super(key: key);

  @override
  State<DynamicAtlasSupportWidget> createState() =>
      DynamicAtlasSupportWidgetState();
}
