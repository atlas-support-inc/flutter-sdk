library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_controllable_widget.dart';
import '_dynamic_atlas_support_widget.dart';

class DynamicAtlasSupportWidgetState extends State<DynamicAtlasSupportWidget> {
  String? _atlasId;
  String? _userId;
  String? _userHash;
  String? _userName;
  String? _userEmail;
  Function? _destroyNotifier;

  @override
  void initState() {
    super.initState();
    _atlasId = widget.initialAtlasId;
    _userId = widget.initialUserId;
    _userHash = widget.initialUserHash;
    _userName = widget.initialUserName;
    _userEmail = widget.initialUserEmail;

    _destroyNotifier = widget.registerIdentityChangeListener((newIdentity) {
      setState(() {
        _atlasId = newIdentity['atlasId'];
        _userId = newIdentity['userId'];
        _userHash = newIdentity['userHash'];
        _userName = newIdentity['userName'];
        _userEmail = newIdentity['userEmail'];
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
        atlasId: _atlasId,
        userId: _userId,
        userHash: _userHash,
        userName: _userName,
        userEmail: _userEmail,
        onError: widget.onError,
        onNewTicket: widget.onNewTicket,
        onChangeIdentity: widget.onChangeIdentity,
        controller: widget.controller,
        onNewController: widget.onNewController);
  }
}
