library atlas_support_sdk;

import 'package:flutter/material.dart';
import 'atlas_support_widget_state.dart';

typedef AtlasWidgetNewTicketHandler = void Function(
    Map<String, dynamic> ticket);

typedef AtlasWidgetErrorHandler = void Function(dynamic message);

class AtlasSupportWidget extends StatefulWidget {
  final String appId;
  final String userId;
  final String? userHash;
  final String? userName;
  final String? userEmail;
  final AtlasWidgetNewTicketHandler? onNewTicket;
  final AtlasWidgetErrorHandler? onError;

  const AtlasSupportWidget(
      {Key? key,
      required this.appId,
      required this.userId,
      this.userHash,
      this.userName,
      this.userEmail,
      this.onNewTicket,
      this.onError})
      : super(key: key);

  @override
  State<AtlasSupportWidget> createState() => AtlasSupportWidgetState();
}
