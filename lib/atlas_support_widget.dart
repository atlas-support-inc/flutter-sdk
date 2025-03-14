library atlas_support_sdk;

import 'package:flutter/material.dart';
import 'atlas_support_widget_state.dart';

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
  final String? atlasId;
  final String? userId;
  final String? userHash;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final AtlasWidgetChatStartedHandler? onChatStarted;
  final AtlasWidgetNewTicketHandler? onNewTicket;
  final AtlasWidgetChangeIdentityHandler? onChangeIdentity;
  final AtlasWidgetErrorHandler? onError;

  const AtlasSupportWidget(
      {Key? key,
      required this.appId,
      this.query,
      this.atlasId,
      this.userId,
      this.userHash,
      this.name,
      this.email,
      this.phoneNumber,
      this.onChatStarted,
      this.onNewTicket,
      this.onChangeIdentity,
      this.onError})
      : super(key: key);

  @override
  State<AtlasSupportWidget> createState() => AtlasSupportWidgetState();
}
