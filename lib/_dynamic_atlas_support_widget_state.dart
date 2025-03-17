library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_controllable_widget.dart';
import '_dynamic_atlas_support_widget.dart';

class DynamicAtlasSupportWidgetState extends State<DynamicAtlasSupportWidget> {
  String? _query;
  String? _userId;
  String? _userHash;
  Function? _destroyNotifier;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _userId = widget.initialUserId;
    _userHash = widget.initialUserHash;

    _destroyNotifier = widget.registerIdentityChangeListener((newIdentity) {
      setState(() {
        _userId = newIdentity['userId'];
        _userHash = newIdentity['userHash'];
      });
    });
  }

  @override
  dispose() {
    super.dispose();
    _destroyNotifier?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AtlasSupportControllableWidget(
        appId: widget.appId,
        query: _query,
        userId: _userId,
        userHash: _userHash,
        onError: widget.onError,
        onChatStarted: widget.onChatStarted,
        onNewTicket: widget.onNewTicket,
        onChangeIdentity: widget.onChangeIdentity,
        controller: widget.controller,
        onNewController: widget.onNewController);
  }
}
