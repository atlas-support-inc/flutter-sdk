library atlas_support_sdk;

import 'package:flutter/material.dart';

import '_atlas_support_controllable_widget.dart';
import '_dynamic_atlas_support_widget.dart';

class DynamicAtlasSupportWidgetState extends State<DynamicAtlasSupportWidget> {
  String? _query;
  String? _atlasId;
  Function? _destroyNotifier;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _atlasId = widget.initialAtlasId;

    _destroyNotifier = widget.registerIdentityChangeListener((newIdentity) {
      setState(() {
        _atlasId = newIdentity['atlasId'];
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
        onError: widget.onError,
        onChatStarted: widget.onChatStarted,
        onNewTicket: widget.onNewTicket,
        onChangeIdentity: widget.onChangeIdentity,
        controller: widget.controller,
        onNewController: widget.onNewController);
  }
}
