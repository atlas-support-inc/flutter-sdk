import 'package:atlas_support_sdk/_login.dart';
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

void log(dynamic message) {
  // ignore: avoid_print
  print(message);
}

class AtlasSDK {
  static String? _appId;
  static String? _atlasId;

  static void _forceReload() {
    // TODO: Force all SDK modules to reload
    log("In $_appId with $_atlasId");
  }

  static void setAppId(String appId) {
    if (_appId == appId) return;

    _appId = appId;
    _atlasId = null;
    _forceReload();

    SharedPreferences.getInstance().then((preferences) {
      String? atlasId = preferences.getString(storageAtlasIdKey);
      if (atlasId == null) return;
      if (_atlasId != null) return;

      _atlasId = atlasId;
      _forceReload();
    });
  }

  static void logout() {
    _atlasId = null;
    _forceReload();
  }

  static Future<void> identify(
      {required String userId, String? userHash, String? name, String? email, String? phoneNumber}) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      log("AtlasSupportSDK: Cannot call identify() without App ID set");
      return;
    }

    return login(appId: appId, userId: userId, userHash: userHash, name: name, email: email, phoneNumber: phoneNumber)
        .then((customer) {
      var atlasId = customer['id'];
      if (_atlasId == atlasId) return;
      if (atlasId is! String) {
        log("AtlasSupportSDK: Invalid atlasId type. Expected String, got ${atlasId.runtimeType}");
        return;
      }

      SharedPreferences.getInstance().then((preferences) {
        preferences.setString(storageAtlasIdKey, atlasId);
      });

      _atlasId = atlasId;
      _forceReload();
    }).catchError((error) {
      // TODO: send to error handler
      log(error);
      logout();
    });
  }

  Future<void> updateCustomFields(String ticketId, Map<String, dynamic> customFields) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      log("AtlasSupportSDK: Cannot call identify() without App ID set");
      return;
    }
  }

  watchStats(StatsChangeCallback listener, [AtlasErrorHandler? onError]) {
    var appId = _appId;
    if (appId == null || appId == "") {
      log("AtlasSupportSDK: Cannot call identify() without App ID set");
      return;
    }
  }

  // ignore: non_constant_identifier_names
  static Widget({String? query, String? persist}) {
    var appId = _appId;
    if (appId == null || appId == "") {
      log("AtlasSupportSDK: Cannot call identify() without App ID set");
      return;
    }

    log("App ID: $appId");

    return DynamicAtlasSupportWidget(
      appId: appId,
      query: query,
      initialAtlasId: _atlasId,
      // onError: (message) {
      //   onError?.call(message);
      //   _onError?.call(message);
      // },
      // onNewTicket: (Map<String, dynamic> ticket) {
      //   onNewTicket?.call(ticket);
      //   _onNewTicket?.call(ticket);
      // },
      // onChangeIdentity: (Map<String, dynamic> data) async {
      //   final SharedPreferences preferences = await SharedPreferences.getInstance();
      //   preferences.setString(storageAtlasIdKey, data['atlasId']);

      //   identify(atlasId: data['atlasId']);
      //   onChangeIdentity?.call(data);
      //   _onChangeIdentity?.call(data);
      // },
      // controller: persist != null ? _controllers[persist] : null,
      onNewController: null,
      registerIdentityChangeListener: (Function listener) {
        // _listeners.add(listener);
        // return () => _listeners.remove(listener);
      },
    );
  }

  onError(AtlasErrorHandler? onError) {}

  onNewTicket(AtlasNewTicketHandler? onNewTicket) {}

  onChangeIdentity(AtlasChangeIdentityHandler? onChangeIdentity) {}
}

class AtlasSupportSDK {
  final String appId;
  final AtlasErrorHandler? _onError;
  final AtlasNewTicketHandler? _onNewTicket;
  final AtlasChangeIdentityHandler? _onChangeIdentity;
  String? _atlasId;
  String? _userId;
  String? _userHash;
  String? _name;
  String? _email;
  String? _phoneNumber;

  final List<Function> _listeners = [];
  final Map<String, WebViewController> _controllers = {};

  AtlasSupportSDK(
      {required this.appId,
      String? atlasId,
      String? userId,
      String? userHash,
      String? name,
      String? email,
      String? phoneNumber,
      AtlasErrorHandler? onError,
      AtlasNewTicketHandler? onChangeIdentity,
      AtlasNewTicketHandler? onNewTicket})
      : _atlasId = atlasId,
        _userId = userId,
        _userHash = userHash,
        _name = name,
        _email = email,
        _phoneNumber = phoneNumber,
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
      initialUserName: _name,
      initialUserEmail: _email,
      initialUserPhoneNumber: _phoneNumber,
      onError: (message) {
        onError?.call(message);
        _onError?.call(message);
      },
      onNewTicket: (Map<String, dynamic> ticket) {
        onNewTicket?.call(ticket);
        _onNewTicket?.call(ticket);
      },
      onChangeIdentity: (Map<String, dynamic> data) async {
        final SharedPreferences preferences = await SharedPreferences.getInstance();
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
            name: _name,
            email: _email,
            phoneNumber: _phoneNumber,
            onError: (message) {
              onError?.call(message);
              _onError?.call(message);
            },
            onStatsChange: listener);

    void restart(Map newIdentity) {
      close();
      listener(AtlasStats(conversations: []));
      close = (newIdentity['atlasId'] == null && (newIdentity['userId'] == null || newIdentity['userId'] == ""))
          ? () {}
          : watchAtlasSupportStats(
              appId: appId,
              atlasId: newIdentity['atlasId'],
              userId: newIdentity['userId'],
              userHash: newIdentity['userHash'],
              name: newIdentity['name'],
              email: newIdentity['email'],
              phoneNumber: newIdentity['phoneNumber'],
              onStatsChange: listener);
    }

    _listeners.add(restart);

    return close;
  }

  void identify({String? atlasId, String? userId, String? userHash, String? name, String? email, String? phoneNumber}) {
    _atlasId = atlasId;
    _userId = userId;
    _userHash = userHash;
    _name = name;
    _email = email;
    _phoneNumber = phoneNumber;

    _controllers.clear();

    for (var listener in _listeners) {
      listener({
        'atlasId': _atlasId,
        'userId': _userId,
        'userHash': _userHash,
        'name': _name,
        'email': _email,
        'phoneNumber': _phoneNumber
      });
    }
  }

  Future<void> updateCustomFields(String ticketId, Map<String, dynamic> customFields) async {
    var atlasId = _atlasId;
    if (atlasId == null) {
      return Future.error('Session is not initialized');
    }

    await updateAtlasCustomFields(atlasId, ticketId, customFields, userHash: _userHash);
  }
}

AtlasSupportSDK createAtlasSupportSDK(
    {required String appId,
    String? userId,
    String? userHash,
    String? name,
    String? email,
    String? phoneNumber,
    AtlasErrorHandler? onError,
    AtlasNewTicketHandler? onNewTicket,
    AtlasChangeIdentityHandler? onChangeIdentity}) {
  var sdk = AtlasSupportSDK(
      appId: appId,
      userId: userId,
      userHash: userHash,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
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
