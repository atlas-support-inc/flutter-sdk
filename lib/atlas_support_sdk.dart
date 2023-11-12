import 'package:webview_flutter/webview_flutter.dart';

import 'atlas_stats.dart';
import 'watch_atlas_support_stats.dart';
import '_dynamic_atlas_support_widget.dart';

typedef AtlasErrorHandler = void Function(dynamic message);

class AtlasSupportSDK {
  final String appId;
  final AtlasErrorHandler? _onError;
  String? _userId;
  String? _userHash;
  String? _userName;
  String? _userEmail;

  final List<Function> _listeners = [];
  final Map<String, WebViewController> _controllers = {};

  AtlasSupportSDK(
      {required this.appId,
      String? userId,
      String? userHash,
      String? userName,
      String? userEmail,
      AtlasErrorHandler? onError})
      : _userId = userId,
        _userHash = userHash,
        _userName = userName,
        _userEmail = userEmail,
        _onError = onError;

  Widget({String? persist, AtlasErrorHandler? onError}) {
    return DynamicAtlasSupportWidget(
      appId: appId,
      initialUserId: _userId,
      initialUserHash: _userHash,
      initialUserName: _userName,
      initialUserEmail: _userEmail,
      onError: (message) {
        onError?.call(message);
        _onError?.call(message);
      },
      controller: persist != null ? _controllers[persist] : null,
      onNewController: persist != null
          ? (WebViewController controller) {
              _controllers[persist] = controller;
            }
          : null,
      changeIdentityNotifier: (Function listener) {
        _listeners.add(listener);
        return () => _listeners.remove(listener);
      },
    );
  }

  watchStats(StatsChangeCallback listener, [AtlasErrorHandler? onError]) {
    var userId = _userId;
    var userHash = _userHash;

    if (userId == null || userHash == null) {
      listener(AtlasStats(conversations: []));
    }

    var close = userId == null || userHash == null
        ? () {}
        : watchAtlasSupportStats(
            appId: appId,
            userId: userId,
            userHash: userHash,
            userName: _userName,
            userEmail: _userEmail,
            onError: (message) {
              onError?.call(message);
              _onError?.call(message);
            },
            onStatsChange: listener);

    void restart(Map newIdentity) {
      close();
      listener(AtlasStats(conversations: []));
      close = newIdentity['userId'] == null || newIdentity['userHash'] == null
          ? () {}
          : watchAtlasSupportStats(
              appId: appId,
              userId: newIdentity['userId'],
              userHash: newIdentity['userHash'],
              userName: newIdentity['userName'],
              userEmail: newIdentity['userEmail'],
              onStatsChange: listener);
    }

    _listeners.add(restart);

    return close;
  }

  void identify(
      {String? userId, String? userHash, String? userName, String? userEmail}) {
    _userId = userId;
    _userHash = userHash;
    _userName = userName;
    _userEmail = userEmail;

    _controllers.clear();

    for (var listener in _listeners) {
      listener({
        'userId': _userId,
        'userHash': _userHash,
        'userName': _userName,
        'userEmail': _userEmail
      });
    }
  }
}

AtlasSupportSDK createAtlasSupportSDK(
        {required String appId,
        String? userId,
        String? userHash,
        String? userName,
        String? userEmail,
        AtlasErrorHandler? onError}) =>
    AtlasSupportSDK(
        appId: appId,
        userId: userId,
        userHash: userHash,
        userName: userName,
        userEmail: userEmail,
        onError: onError);
