library atlas_support_sdk;

import 'package:webview_flutter/webview_flutter.dart';

import '_atlas_support_widget_state.dart';
import '_atlas_support_controllable_widget.dart';

class AtlasSupportControllableWidgetState extends AtlasSupportWidgetState {
  @override
  WebViewController initController() {
    var controllableWidget = widget as AtlasSupportControllableWidget;
    var ctrl = controllableWidget.controller;
    if (ctrl != null) return ctrl;
    var controller = super.initController();
    controllableWidget.onNewController?.call(controller);
    return controller;
  }
}
