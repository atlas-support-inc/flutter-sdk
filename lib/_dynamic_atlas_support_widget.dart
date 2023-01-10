library atlas_support_sdk;

import 'package:flutter/material.dart';
import '_dynamic_atlas_support_widget_state.dart';

class DynamicAtlasSupportWidget extends StatefulWidget {
  final String appId;
  final String? initialUserId;
  final String? initialUserHash;
  final String? initialUserName;
  final String? initialUserEmail;
  final Function changeIdentityNotifier;

  const DynamicAtlasSupportWidget(
      {Key? key,
      required this.appId,
      this.initialUserId,
      this.initialUserHash,
      this.initialUserName,
      this.initialUserEmail,
      required this.changeIdentityNotifier})
      : super(key: key);

  @override
  State<DynamicAtlasSupportWidget> createState() =>
      DynamicAtlasSupportWidgetState();
}
