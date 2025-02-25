import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'atlas_stats.dart';
import 'watch_atlas_support_stats.dart';
import '_dynamic_atlas_support_widget.dart';
import 'update_atlas_custom_fields.dart';

typedef AtlasErrorHandler = void Function(dynamic message);

typedef AtlasNewTicketHandler = void Function(Map<String, dynamic> ticket);

typedef AtlasChangeIdentityHandler = void Function(Map<String, dynamic> data);

const storageAtlasIdKey = '@atlas.so/atlasId';

class AtlasSupportSDK {
  final String appId;
  final AtlasErrorHandler? _onError;
  final AtlasNewTicketHandler? _onNewTicket;
  final AtlasChangeIdentityHandler? _onChangeIdentity;
  String? _atlasId;
  String? _userId;
  String? _userHash;
  String? _userName;
  String? _userEmail;

  final List<Function> _listeners = [];
  final Map<String, WebViewController> _controllers = {};

  AtlasSupportSDK(
      {required this.appId,
      String? atlasId,
      String? userId,
      String? userHash,
      String? userName,
      String? userEmail,
      AtlasErrorHandler? onError,
      AtlasNewTicketHandler? onChangeIdentity,
      AtlasNewTicketHandler? onNewTicket})
      : _atlasId = atlasId,
        _userId = userId,
        _userHash = userHash,
        _userName = userName,
        _userEmail = userEmail,
        _onError = onError,
        _onChangeIdentity = onChangeIdentity,
        _onNewTicket = onNewTicket;

  // ignore: non_constant_identifier_names
  Widget(
      {String? persist,
      String? query,
      AtlasErrorHandler? onError,
      AtlasNewTicketHandler? onNewTicket,
      AtlasChangeIdentityHandler? onChangeIdentity}) {
    return DynamicAtlasSupportWidget(
      appId: appId,
      query: query,
      initialAtlasId: _atlasId,
      initialUserId: _userId,
      initialUserHash: _userHash,
      initialUserName: _userName,
      initialUserEmail: _userEmail,
      onError: (message) {
        onError?.call(message);
        _onError?.call(message);
      },
      onNewTicket: (Map<String, dynamic> ticket) {
        onNewTicket?.call(ticket);
        _onNewTicket?.call(ticket);
      },
      onChangeIdentity: (Map<String, dynamic> data) async {
        final SharedPreferences preferences =
            await SharedPreferences.getInstance();
        preferences.setString(storageAtlasIdKey, data['atlasId']);

        identify(atlasId: data['atlasId']);
        onChangeIdentity?.call(data);
        _onChangeIdentity?.call(data);
      },
      controller: persist != null ? _controllers[persist] : null,
      onNewController: persist != null
          ? (WebViewController controller) {
              _controllers[persist] = controller;
            }
          : null,
      registerIdentityChangeListener: (Function listener) {
        _listeners.add(listener);
        return () => _listeners.remove(listener);
      },
    );
  }

  watchStats(StatsChangeCallback listener, [AtlasErrorHandler? onError]) {
    if (_atlasId == null && (_userId == null || _userId == "")) {
      listener(AtlasStats(conversations: []));
    }

    var close = (_atlasId == null && (_userId == null || _userId == ""))
        ? () {}
        : watchAtlasSupportStats(
            appId: appId,
            atlasId: _atlasId,
            userId: _userId,
            userHash: _userHash,
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
      close = (newIdentity['atlasId'] == null &&
              (newIdentity['userId'] == null || newIdentity['userId'] == ""))
          ? () {}
          : watchAtlasSupportStats(
              appId: appId,
              atlasId: newIdentity['atlasId'],
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
      {String? atlasId,
      String? userId,
      String? userHash,
      String? userName,
      String? userEmail}) {
    _atlasId = atlasId;
    _userId = userId;
    _userHash = userHash;
    _userName = userName;
    _userEmail = userEmail;

    _controllers.clear();

    for (var listener in _listeners) {
      listener({
        'atlasId': _atlasId,
        'userId': _userId,
        'userHash': _userHash,
        'userName': _userName,
        'userEmail': _userEmail
      });
    }
  }

  Future<void> updateCustomFields(
      String ticketId, Map<String, dynamic> customFields) async {
    var atlasId = _atlasId;
    if (atlasId == null) {
      return Future.error('Session is not initialized');
    }

    await updateAtlasCustomFields(atlasId, ticketId, customFields,
        userHash: _userHash);
  }
}

AtlasSupportSDK createAtlasSupportSDK(
    {required String appId,
    String? userId,
    String? userHash,
    String? userName,
    String? userEmail,
    AtlasErrorHandler? onError,
    AtlasNewTicketHandler? onNewTicket,
    AtlasChangeIdentityHandler? onChangeIdentity}) {
  var sdk = AtlasSupportSDK(
      appId: appId,
      userId: userId,
      userHash: userHash,
      userName: userName,
      userEmail: userEmail,
      onError: onError,
      onNewTicket: onNewTicket,
      onChangeIdentity: onChangeIdentity);

  SharedPreferences.getInstance().then((preferences) {
    String? atlasId = preferences.getString(storageAtlasIdKey);
    if (atlasId != null && sdk._userId == null || sdk._userId == '') {
      sdk.identify(atlasId: atlasId);
    }
  });

  return sdk;
}
