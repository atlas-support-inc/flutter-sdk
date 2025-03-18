library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_widget_state.dart';

typedef AtlasWidgetChatStartedHandler = void Function(
    Map<String, dynamic> ticket); // {String ticketId, String? chatbotKey}

typedef AtlasWidgetNewTicketHandler = void Function(
    Map<String, dynamic> ticket); // {String ticketId}

typedef AtlasWidgetChangeIdentityHandler = void Function(
    Map<String, dynamic> ticket); // {String atlasId}

typedef AtlasWidgetErrorHandler = void Function(dynamic message);

class AtlasSupportWidget extends StatefulWidget {
  final String appId;
  final String? query;
  final String? userId;
  final String? userHash;
  final AtlasWidgetChatStartedHandler? onChatStarted;
  final AtlasWidgetNewTicketHandler? onNewTicket;
  final AtlasWidgetChangeIdentityHandler? onChangeIdentity;
  final AtlasWidgetErrorHandler? onError;

  const AtlasSupportWidget(
      {Key? key,
      required this.appId,
      this.query,
      this.userId,
      this.userHash,
      this.onChatStarted,
      this.onNewTicket,
      this.onChangeIdentity,
      this.onError})
      : super(key: key);

  @override
  State<AtlasSupportWidget> createState() => AtlasSupportWidgetState();
}
