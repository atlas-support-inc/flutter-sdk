library atlas_support_sdk;

import 'package:atlas_support_sdk/atlas_support_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '_atlas_support_controllable_widget_state.dart';

class AtlasSupportControllableWidget extends AtlasSupportWidget {
  final WebViewController? controller;
  final Function(WebViewController controller)? onNewController;

  const AtlasSupportControllableWidget({
    Key? key,
    required String appId,
    String? query,
    String? atlasId,
    String? userId,
    String? userHash,
    String? userName,
    String? userEmail,
    AtlasWidgetErrorHandler? onError,
    AtlasWidgetNewTicketHandler? onNewTicket,
    AtlasWidgetNewTicketHandler? onChangeIdentity,
    this.controller,
    this.onNewController,
  }) : super(
            key: key,
            appId: appId,
            query: query,
            atlasId: atlasId,
            userId: userId,
            userHash: userHash,
            userName: userName,
            userEmail: userEmail,
            onError: onError,
            onNewTicket: onNewTicket,
            onChangeIdentity: onChangeIdentity);

  @override
  State<AtlasSupportWidget> createState() =>
      AtlasSupportControllableWidgetState();
}
