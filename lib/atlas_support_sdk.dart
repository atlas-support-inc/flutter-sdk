// TODO: When chatbot get the first user input this error is thrown:
// The following _TypeError was thrown during a platform message callback:
// Null check operator used on a null value

import 'package:atlas_support_sdk/_login.dart';
import 'package:atlas_support_sdk/watch_new_atlas_support_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'atlas_stats.dart';
import 'watch_atlas_support_stats.dart';
import '_dynamic_atlas_support_widget.dart';
import 'update_atlas_custom_fields.dart';

class AtlasError {
  final String message;
  final dynamic original;
  AtlasError(this.message, [this.original]);
}

typedef AtlasNewErrorHandler = void Function(AtlasError error);

class AtlasChatStarted {
  final String ticketId;
  final String? chatbotKey;
  AtlasChatStarted(this.ticketId, this.chatbotKey);
}

typedef AtlasChatStartedHandler = void Function(AtlasChatStarted ticket);

class AtlasChangeIdentity {
  final String atlasId;
  AtlasChangeIdentity(this.atlasId);
}

typedef AtlasNewChangeIdentityHandler = void Function(AtlasChangeIdentity? identity);

String storageAtlasId(String appId) => '@atlas.so/$appId/atlasId';

class AtlasSDK {
  static String? _appId;
  static String? _atlasId;

  static final List<AtlasNewErrorHandler> _errorHandlers = [];
  static final List<AtlasChatStartedHandler> _chatStartedHandlers = [];
  static final List<AtlasNewChangeIdentityHandler> _changeIdentityHandlers = [];

  static final Map<String, WebViewController> _controllers = {};

  static String? getAtlasId() => _atlasId;

  static _triggerErrorHandlers(AtlasError error, [AtlasNewErrorHandler? customHandler]) {
    var handlers = customHandler != null ? [customHandler, ..._errorHandlers] : _errorHandlers;
    for (var handler in handlers) {
      try {
        handler(error);
      } catch (e) {
        print("AtlasSupportSDK: Error in error handler");
        print(e);
      }
    }
  }

  static _triggerNewTicketHandlers(AtlasChatStarted chatStarted, [AtlasChatStartedHandler? customHandler]) {
    var handlers = customHandler != null ? [customHandler, ..._chatStartedHandlers] : _chatStartedHandlers;
    for (var handler in handlers) {
      try {
        handler(chatStarted);
      } catch (e) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Error in new ticket handler", e));
      }
    }
  }

  static _triggerChangeIdentityHandlers(AtlasChangeIdentity? changeIdentity,
      [AtlasNewChangeIdentityHandler? customHandler]) {
    _controllers.clear();
    var handlers = customHandler != null ? [customHandler, ..._changeIdentityHandlers] : _changeIdentityHandlers;
    for (var handler in handlers) {
      try {
        handler(changeIdentity);
      } catch (e) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Error in change identity handler", e));
      }
    }
  }

  static Future<void> setAppId(String appId) async {
    if (_appId == appId) return;

    _appId = appId;
    _atlasId = null;

    try {
      final preferences = await SharedPreferences.getInstance();
      String? atlasId = preferences.getString(storageAtlasId(appId));

      // If user was authenticated while settings were loading, we assume that SDK was already reloaded
      if (_atlasId == null) {
        if (atlasId != null) {
          _atlasId = atlasId;
          _triggerChangeIdentityHandlers(AtlasChangeIdentity(atlasId));
        }
      }
    } catch (error) {
      _triggerChangeIdentityHandlers(null);
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Failed to set Atlas ID", error));
    }
  }

  static Future<void> _setAtlasId(String atlasId, AtlasNewChangeIdentityHandler? onChange) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot change Atlas ID without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    if (_atlasId == atlasId) return;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString(storageAtlasId(appId), atlasId);
    _atlasId = atlasId;

    _triggerChangeIdentityHandlers(AtlasChangeIdentity(atlasId), onChange);
  }

  static void logout() {
    _atlasId = null;
    _triggerChangeIdentityHandlers(null);
  }

  static Future<void> identify(
      {required String userId,
      String? userHash,
      String? name,
      String? email,
      String? phoneNumber,
      AtlasNewChangeIdentityHandler? onChange,
      AtlasNewErrorHandler? onError}) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call identify() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage), onError);
      throw Exception(errorMessage);
    }

    return login(appId: appId, userId: userId, userHash: userHash, name: name, email: email, phoneNumber: phoneNumber)
        .then((customer) async {
      var atlasId = customer['id'];
      if (_atlasId == atlasId) return;
      if (atlasId is! String) {
        var errorMessage = "AtlasSupportSDK: Invalid atlasId type. Expected String, got ${atlasId.runtimeType}";
        _triggerErrorHandlers(AtlasError(errorMessage), onError);
        throw Exception(errorMessage);
      }

      await _setAtlasId(atlasId, onChange);
    }).catchError((error) {
      var errorMessage = "AtlasSupportSDK: Failed to identify user";
      _triggerErrorHandlers(AtlasError(errorMessage, error), onError);
      logout();
      throw Exception(errorMessage);
    });
  }

  Future<void> updateCustomFields(String ticketId, Map<String, dynamic> customFields) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call updateCustomFields() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }
  }

  static watchStats(AtlasNewStatsChangeCallback callback, [AtlasNewWatcherErrorHandler? onError]) {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call watchStats() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    var atlasId = _atlasId;

    // Unsubscribe if any and reset itself to prevent duplicate call to unsubscribe
    Function? dispose;

    void subscribe(String atlasId) {
      Function? unsubscribe;
      
      dispose?.call();
      dispose = () {
        dispose = null;
        unsubscribe?.call();
      };

      unsubscribe = watchNewAtlasSupportStats(
          appId: appId,
          atlasId: atlasId,
          onStatsChange: callback,
          onError: (error) =>
              _triggerErrorHandlers(AtlasError("AtlasSupportSDK: WebSocket thrown an error", error), onError));

    }

    if (atlasId != null) subscribe(atlasId);

    void restart(AtlasChangeIdentity? identity) {
      dispose?.call();
      callback(AtlasStats(conversations: []));
      if (identity != null) subscribe(identity.atlasId);
    }

    onChangeIdentity(restart);

    return () => dispose?.call();
  }

  // ignore: non_constant_identifier_names
  static Widget(
      {String? query,
      String? persist,
      AtlasNewErrorHandler? onError,
      AtlasChatStartedHandler? onChatStarted,
      AtlasNewChangeIdentityHandler? onChangeIdentity}) {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot render Widget() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    return DynamicAtlasSupportWidget(
      appId: appId,
      query: query,
      initialAtlasId: _atlasId,
      onError: (error) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Widget reported error", error), onError);
      },
      onChatStarted: (Map<String, dynamic> data) {
        var ticketId = data['ticketId'];
        var chatbotKey = data['chatbotKey'];
        if (ticketId is String) {
          var chatStarted = AtlasChatStarted(ticketId, chatbotKey);
          _triggerNewTicketHandlers(chatStarted, onChatStarted);
        } else {
          _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Received invalid ticket data ($data)"), onError);
        }
      },
      onChangeIdentity: (Map<String, dynamic> data) {
        var atlasId = data['atlasId'];
        if (_atlasId == atlasId) return;

        if (atlasId is String) {
          _setAtlasId(atlasId, onChangeIdentity);
        } else {
          _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Received invalid change identity data ($data)"), onError);
        }
      },
      controller: persist != null ? _controllers[persist] : null,
      onNewController: persist != null
          ? (WebViewController controller) {
              _controllers[persist] = controller;
            }
          : null,
      registerIdentityChangeListener: (Function listener) {
        return AtlasSDK.onChangeIdentity((identity) {
          if (identity == null) {
            listener(null);
          } else {
            listener({'atlasId': identity.atlasId});
          }
        });
      },
    );
  }

  static onError(AtlasNewErrorHandler onError) {
    _errorHandlers.add(onError);
    return () => _errorHandlers.remove(onError);
  }

  // TODO: It seems that embed doesn't send the message when chat is started with chatbot
  // static onChatStarted(AtlasChatStartedHandler onChatStarted) {
  //   _chatStartedHandlers.add(onChatStarted);
  //   return () => _chatStartedHandlers.remove(onChatStarted);
  // }

  static onChangeIdentity(AtlasNewChangeIdentityHandler onChangeIdentity) {
    _changeIdentityHandlers.add(onChangeIdentity);
    return () => _changeIdentityHandlers.remove(onChangeIdentity);
  }
}

const storageAtlasIdKey = '@atlas.so/atlasId';

typedef AtlasErrorHandler = void Function(dynamic message);
typedef AtlasNewTicketHandler = void Function(Map<String, dynamic> ticket);
typedef AtlasChangeIdentityHandler = void Function(Map<String, dynamic> data);

class AtlasSupportSDK {
  final String appId;
  final AtlasErrorHandler? _onError;
  final AtlasChatStartedHandler? _onChatStarted;
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
      AtlasChatStartedHandler? onChatStarted,
      AtlasNewTicketHandler? onNewTicket})
      : _atlasId = atlasId,
        _userId = userId,
        _userHash = userHash,
        _name = name,
        _email = email,
        _phoneNumber = phoneNumber,
        _onError = onError,
        _onChangeIdentity = onChangeIdentity,
        _onChatStarted = onChatStarted,
        _onNewTicket = onNewTicket;

  // ignore: non_constant_identifier_names
  Widget(
      {String? persist,
      String? query,
      AtlasErrorHandler? onError,
      AtlasChatStartedHandler? onChatStarted,
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
      onChatStarted: (Map<String, dynamic> data) {
        var ticketId = data['ticketId'];
        var chatbotKey = data['chatbotKey'];
        if (ticketId is String) {
          var chatStarted = AtlasChatStarted(ticketId, chatbotKey);
          onChatStarted?.call(chatStarted);
          _onChatStarted?.call(chatStarted);
        }
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
    AtlasChatStartedHandler? onChatStarted,
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
      onChatStarted: onChatStarted,
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
