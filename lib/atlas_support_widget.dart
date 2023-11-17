library atlas_support_sdk;

import 'package:flutter/material.dart';
import 'atlas_support_widget_state.dart';

typedef AtlasWidgetNewTicketHandler = void Function(
    Map<String, dynamic> ticket); // {String ticketId}

typedef AtlasWidgetChangeIdentityHandler = void Function(
    Map<String, dynamic> ticket); // {String atlasId}

typedef AtlasWidgetErrorHandler = void Function(dynamic message);

class AtlasSupportWidget extends StatefulWidget {
  final String appId;
  final String? atlasId;
  final String? userId;
  final String? userHash;
  final String? userName;
  final String? userEmail;
  final AtlasWidgetNewTicketHandler? onNewTicket;
  final AtlasWidgetChangeIdentityHandler? onChangeIdentity;
  final AtlasWidgetErrorHandler? onError;

  const AtlasSupportWidget(
      {Key? key,
      required this.appId,
      this.atlasId,
      this.userId,
      this.userHash,
      this.userName,
      this.userEmail,
      this.onNewTicket,
      this.onChangeIdentity,
      this.onError})
      : super(key: key);

  @override
  State<AtlasSupportWidget> createState() => AtlasSupportWidgetState();
}
