import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '_login.dart';
import '_watch_atlas_support_stats.dart';
import '_dynamic_atlas_support_widget.dart';
import '_update_atlas_custom_fields.dart';
import '_validate_custom_fields.dart';

void _log(dynamic message) {
  // ignore: avoid_print
  print(message);
}

class AtlasError {
  final String message;
  final dynamic original;
  AtlasError(this.message, [this.original]);
}

typedef AtlasErrorHandler = void Function(AtlasError error);

class AtlasChatStarted {
  final String ticketId;
  final String? chatbotKey;
  AtlasChatStarted(this.ticketId, this.chatbotKey);
}

typedef AtlasChatStartedHandler = void Function(AtlasChatStarted ticket);

class AtlasNewTicket {
  final String ticketId;
  final String? chatbotKey;
  AtlasNewTicket(this.ticketId, this.chatbotKey);
}

typedef AtlasNewTicketHandler = void Function(AtlasNewTicket ticket);

class AtlasChangeIdentity {
  final String atlasId;
  final String userId;
  AtlasChangeIdentity(this.atlasId, this.userId);
}

typedef AtlasChangeIdentityHandler = void Function(AtlasChangeIdentity? identity);

class AtlasIdentity {
  final String atlasId;
  final String userId;
  final String? userHash;

  AtlasIdentity({
    required this.atlasId,
    required this.userId,
    this.userHash,
  });

  Map<String, dynamic> toJson() => {
        'atlasId': atlasId,
        'userId': userId,
        if (userHash != null) 'userHash': userHash,
      };

  static AtlasIdentity? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    var atlasId = json['atlasId'];
    var userId = json['userId'];

    if (atlasId == null || atlasId is! String || userId == null || userId is! String) {
      return null;
    }

    var userHash = json['userHash'];
    if (userHash != null && userHash is! String) {
      return null;
    }

    return AtlasIdentity(
      atlasId: atlasId,
      userId: userId,
      userHash: userHash,
    );
  }
}

String _storageIdentityKey(String appId) => '@atlas.so/$appId/identity';

class AtlasSDK {
  static String? _appId;
  static AtlasIdentity? _identity;

  static final List<AtlasErrorHandler> _errorHandlers = [];
  static final List<AtlasChatStartedHandler> _chatStartedHandlers = [];
  static final List<AtlasNewTicketHandler> _newTicketHandlers = [];
  static final List<AtlasChangeIdentityHandler> _changeIdentityHandlers = [];

  static final Map<String, WebViewController> _controllers = {};

  static String? getAtlasId() => _identity?.atlasId;
  static String? getUserId() => _identity?.userId;

  static Map<String, dynamic>? _validateNewTicketData(dynamic data, AtlasErrorHandler? onError) {
    if (data is! Map) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Received invalid ticket data format"), onError);
      return null;
    }

    var ticketId = data['ticketId'];
    var chatbotKey = data['chatbotKey'];

    if (ticketId == null || ticketId is! String) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Missing or invalid ticketId in ticket data"), onError);
      return null;
    }

    if (chatbotKey != null && chatbotKey is! String) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Invalid chatbotKey type in ticket data"), onError);
      return null;
    }

    return {
      'ticketId': ticketId,
      'chatbotKey': chatbotKey,
    };
  }

  static Map<String, dynamic>? _validateIdentityData(dynamic data, AtlasErrorHandler? onError) {
    if (data is! Map) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Received invalid identity data format"), onError);
      return null;
    }

    var atlasId = data['atlasId'];
    var userId = data['userId'];
    var userHash = data['userHash'];

    if (atlasId == null || atlasId is! String) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Missing or invalid atlasId in identity data"), onError);
      return null;
    }

    if (userId == null || userId is! String) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Missing or invalid userId in identity data"), onError);
      return null;
    }

    if (userHash != null && userHash is! String) {
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Invalid userHash type in identity data"), onError);
      return null;
    }

    return {
      'atlasId': atlasId,
      'userId': userId,
      'userHash': userHash,
    };
  }

  static _triggerErrorHandlers(AtlasError error, [AtlasErrorHandler? customHandler]) {
    var handlers = customHandler != null ? [customHandler, ..._errorHandlers] : _errorHandlers;
    for (var handler in handlers) {
      try {
        handler(error);
      } catch (e) {
        _log("AtlasSupportSDK: Error in error handler");
        _log(e);
      }
    }
  }

  static _triggerChatStartedHandlers(AtlasChatStarted chatStarted, [AtlasChatStartedHandler? customHandler]) {
    var handlers = customHandler != null ? [customHandler, ..._chatStartedHandlers] : _chatStartedHandlers;
    for (var handler in handlers) {
      try {
        handler(chatStarted);
      } catch (e) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Error in chat started handler", e));
      }
    }
  }

  static _triggerNewTicketHandlers(AtlasNewTicket newTicket, [AtlasNewTicketHandler? customHandler]) {
    var handlers = customHandler != null ? [customHandler, ..._newTicketHandlers] : _newTicketHandlers;
    for (var handler in handlers) {
      try {
        handler(newTicket);
      } catch (e) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Error in new ticket handler", e));
      }
    }
  }

  static _triggerChangeIdentityHandlers(AtlasChangeIdentity? changeIdentity, [AtlasChangeIdentityHandler? customHandler]) {
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
    _identity = null;

    try {
      final preferences = await SharedPreferences.getInstance();
      String? identityJson = preferences.getString(_storageIdentityKey(appId));

      if (identityJson != null) {
        try {
          var identityData = jsonDecode(identityJson);
          _identity = AtlasIdentity.fromJson(identityData);
          var identity = _identity;
          if (identity != null) {
            _triggerChangeIdentityHandlers(AtlasChangeIdentity(identity.atlasId, identity.userId));
          }
        } catch (e) {
          _log("AtlasSupportSDK: Failed to parse stored identity data");
        }
      }
    } catch (error) {
      _triggerChangeIdentityHandlers(null);
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Failed to set App ID", error));
    }
  }

  static Future<void> _setAtlasIdentity(AtlasIdentity identity, AtlasChangeIdentityHandler? onChange) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot change identity without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    if (_identity?.atlasId == identity.atlasId && _identity?.userId == identity.userId) return;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _identity = identity;
    await preferences.setString(_storageIdentityKey(appId), jsonEncode(identity.toJson()));
    _triggerChangeIdentityHandlers(AtlasChangeIdentity(identity.atlasId, identity.userId), onChange);
  }

  static Future<void> logout() async {
    var appId = _appId;
    if (appId != null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_storageIdentityKey(appId));
      } catch (error) {
        _log("AtlasSupportSDK: Failed to clear stored data");
        _log(error);
      }
    }
    _identity = null;
    _triggerChangeIdentityHandlers(null);
  }

  static Future<void> identify(
      {required String userId,
      String? userHash,
      String? name,
      String? email,
      String? phoneNumber,
      AtlasCustomFields? customFields,
      AtlasChangeIdentityHandler? onChange,
      AtlasErrorHandler? onError}) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call identify() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage), onError);
      throw Exception(errorMessage);
    }

    // Validate custom fields
    final validationErrors = validateCustomFields(customFields);
    if (validationErrors.isNotEmpty) {
      var errorMessage = "AtlasSupportSDK: Invalid custom fields:\n${validationErrors.join("\n")}";
      _triggerErrorHandlers(AtlasError(errorMessage), onError);
      throw Exception(errorMessage);
    }

    return login(
            appId: appId,
            userId: userId,
            userHash: userHash,
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            customFields: customFields)
        .then((customer) async {
      var atlasId = customer is Map ? customer['id'] : null;
      if (atlasId is! String) {
        var errorMessage = "AtlasSupportSDK: Invalid atlasId type. Expected String, got ${atlasId.runtimeType}";
        _triggerErrorHandlers(AtlasError(errorMessage), onError);
        throw Exception(errorMessage);
      }

      // Check if user identity was switched
      bool hasSwitched = _identity == null || _identity!.userId != userId || _identity!.userHash != userHash || _identity!.atlasId != atlasId;

      if (hasSwitched) {
        await _setAtlasIdentity(
            AtlasIdentity(
              atlasId: atlasId,
              userId: userId,
              userHash: userHash,
            ),
            onChange);
      }
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

    var atlasId = _identity?.atlasId;
    if (atlasId == null || atlasId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call updateCustomFields() without Atlas ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    if (_identity == null) {
      var errorMessage = "AtlasSupportSDK: Cannot call updateCustomFields() while not authenticated";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    // Validate custom fields
    final validationErrors = validateCustomFields(customFields);
    if (validationErrors.isNotEmpty) {
      var errorMessage = "AtlasSupportSDK: Invalid custom fields:\n${validationErrors.join("\n")}";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    await updateAtlasCustomFields(atlasId, ticketId, customFields, userHash: _identity!.userHash);
  }

  static watchStats(AtlasWatcherStatsChangeHandler callback, [AtlasWatcherErrorHandler? onError]) {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot call watchStats() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    // Unsubscribe if any and reset itself to prevent duplicate call to unsubscribe
    Function? dispose;

    void subscribe(AtlasIdentity identity) {
      Function? unsubscribe;

      dispose?.call();
      dispose = () {
        dispose = null;
        unsubscribe?.call();
      };

      unsubscribe = watchAtlasSupportStats(
          appId: appId,
          atlasId: identity.atlasId,
          userId: identity.userId,
          userHash: identity.userHash,
          onStatsChange: callback,
          onError: (error) =>
              _triggerErrorHandlers(AtlasError("AtlasSupportSDK: WebSocket thrown an error", error), onError));
    }

    var identity = _identity;
    if (identity != null) subscribe(identity);

    void restart(AtlasChangeIdentity? changeIdentity) {
      dispose?.call();
      callback(AtlasConversationsStats(conversations: []));
      var identity = _identity;
      if (identity != null && identity.atlasId == changeIdentity?.atlasId && identity.userId == changeIdentity?.userId) {
        subscribe(identity);
      }
    }

    onChangeIdentity(restart);

    return () => dispose?.call();
  }

  // ignore: non_constant_identifier_names
  static Widget(
      {String? query,
      String? persist,
      AtlasErrorHandler? onError,
      AtlasChatStartedHandler? onChatStarted,
      AtlasNewTicketHandler? onNewTicket,
      AtlasChangeIdentityHandler? onChangeIdentity}) {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot render Widget() without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    return DynamicAtlasSupportWidget(
      appId: appId,
      query: query,
      initialUserId: _identity?.userId,
      initialUserHash: _identity?.userHash,
      onError: (error) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Widget reported error", error), onError);
      },
      onChatStarted: (dynamic data) {
        var validatedData = _validateNewTicketData(data, onError);
        if (validatedData == null) return;

        var chatStarted = AtlasChatStarted(validatedData['ticketId'], validatedData['chatbotKey']);
        _triggerChatStartedHandlers(chatStarted, onChatStarted);
      },
      onNewTicket: (dynamic data) {
        var validatedData = _validateNewTicketData(data, onError);
        if (validatedData == null) return;

        var newTicket = AtlasNewTicket(validatedData['ticketId'], validatedData['chatbotKey']);
        _triggerNewTicketHandlers(newTicket, onNewTicket);
      },
      onChangeIdentity: (dynamic data) {
        var validatedData = _validateIdentityData(data, onError);
        if (validatedData == null) return;

        var atlasId = validatedData['atlasId'];
        if (_identity?.atlasId == atlasId) return;

        _identity = AtlasIdentity(
          atlasId: atlasId,
          userId: validatedData['userId'],
          userHash: validatedData['userHash'],
        );
        _setAtlasIdentity(_identity!, onChangeIdentity);
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

  static onError(AtlasErrorHandler onError) {
    _errorHandlers.add(onError);
    return () => _errorHandlers.remove(onError);
  }

  static onChatStarted(AtlasChatStartedHandler onChatStarted) {
    _chatStartedHandlers.add(onChatStarted);
    return () => _chatStartedHandlers.remove(onChatStarted);
  }

  static onNewTicket(AtlasNewTicketHandler onNewTicket) {
    _newTicketHandlers.add(onNewTicket);
    return () => _newTicketHandlers.remove(onNewTicket);
  }

  static onChangeIdentity(AtlasChangeIdentityHandler onChangeIdentity) {
    _changeIdentityHandlers.add(onChangeIdentity);
    return () => _changeIdentityHandlers.remove(onChangeIdentity);
  }
}
