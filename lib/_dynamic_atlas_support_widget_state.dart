library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_controllable_widget.dart';
import '_dynamic_atlas_support_widget.dart';

class DynamicAtlasSupportWidgetState extends State<DynamicAtlasSupportWidget> {
  String? _userId;
  String? _userHash;
  String? _userName;
  String? _userEmail;
  Function? _destroyNotifier;

  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserId;
    _userHash = widget.initialUserHash;
    _userName = widget.initialUserName;
    _userEmail = widget.initialUserEmail;

    _destroyNotifier = widget.changeIdentityNotifier((newIdentity) {
      setState(() {
        _userId = newIdentity['userId'] ?? _userId;
        _userHash = newIdentity['userHash'] ?? _userHash;
        _userName = newIdentity['userName'] ?? _userName;
        _userEmail = newIdentity['userEmail'] ?? _userEmail;
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
    var userId = _userId;
    var userHash = _userHash;

    if (userId == null || userHash == null) {
      return Container();
    }

    return AtlasSupportControllableWidget(
      appId: widget.appId,
      userId: userId,
      userHash: userHash,
      userName: _userName,
      userEmail: _userEmail,
      controller: widget.controller,
      onNewController: widget.onNewController,
    );
  }
}
