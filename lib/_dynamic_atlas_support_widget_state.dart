library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_controllable_widget.dart';
import '_dynamic_atlas_support_widget.dart';

class DynamicAtlasSupportWidgetState extends State<DynamicAtlasSupportWidget> {
  String? _query;
  String? _atlasId;
  String? _userId;
  String? _userHash;
  String? _name;
  String? _email;
  String? _phoneNumber;
  Function? _destroyNotifier;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _atlasId = widget.initialAtlasId;
    _userId = widget.initialUserId;
    _userHash = widget.initialUserHash;
    _name = widget.initialUserName;
    _email = widget.initialUserEmail;
    _phoneNumber = widget.initialUserPhoneNumber;

    _destroyNotifier = widget.registerIdentityChangeListener((newIdentity) {
      setState(() {
        _atlasId = newIdentity['atlasId'];
        _userId = newIdentity['userId'];
        _userHash = newIdentity['userHash'];
        _name = newIdentity['name'];
        _email = newIdentity['email'];
        _phoneNumber = newIdentity['phoneNumber'];
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
        atlasId: _atlasId,
        userId: _userId,
        userHash: _userHash,
        name: _name,
        email: _email,
        phoneNumber: _phoneNumber,
        onError: widget.onError,
        onChatStarted: widget.onChatStarted,
        onNewTicket: widget.onNewTicket,
        onChangeIdentity: widget.onChangeIdentity,
        controller: widget.controller,
        onNewController: widget.onNewController);
  }
}
