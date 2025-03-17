// TODO: When chatbot get the first user input this error is thrown:
// The following _TypeError was thrown during a platform message callback:
// Null check operator used on a null value

import 'dart:convert';
import 'package:atlas_support_sdk/_login.dart';
import 'package:atlas_support_sdk/watch_atlas_support_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:atlas_support_sdk/_dynamic_atlas_support_widget.dart';
import 'package:atlas_support_sdk/update_atlas_custom_fields.dart';
import 'package:atlas_support_sdk/_validate_custom_fields.dart';

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
  AtlasChangeIdentity(this.atlasId);
}

typedef AtlasChangeIdentityHandler = void Function(AtlasChangeIdentity? identity);

String _storageAtlasId(String appId) => '@atlas.so/$appId/atlasId';
String _storageUserData(String appId) => '@atlas.so/$appId/userData';

bool _areMapsEqual(dynamic map1, dynamic map2) {
  if (map1 == null && map2 == null) return true;
  if (map1 == null || map2 == null) return false;
  if (map1 is! Map || map2 is! Map) return false;
  if (map1.length != map2.length) return false;

  for (var key in map1.keys) {
    if (!map2.containsKey(key)) return false;
    var value1 = map1[key];
    var value2 = map2[key];

    if (value1 is Map && value2 is Map) {
      if (!_areMapsEqual(value1, value2)) return false;
    } else if (value1 is List && value2 is List) {
      if (value1.length != value2.length) return false;
      for (var i = 0; i < value1.length; i++) {
        if (value1[i] is Map && value2[i] is Map) {
          if (!_areMapsEqual(value1[i], value2[i])) return false;
        } else if (value1[i] != value2[i]) {
          return false;
        }
      }
    } else if (value1 != value2) {
      return false;
    }
  }

  return true;
}

class AtlasSDK {
  static String? _appId;
  static String? _atlasId;

  // Store last identified user data
  static Map<String, dynamic>? _lastIdentifiedUser;

  static final List<AtlasErrorHandler> _errorHandlers = [];
  static final List<AtlasChatStartedHandler> _chatStartedHandlers = [];
  static final List<AtlasNewTicketHandler> _newTicketHandlers = [];
  static final List<AtlasChangeIdentityHandler> _changeIdentityHandlers = [];

  static final Map<String, WebViewController> _controllers = {};

  static String? getAtlasId() => _atlasId;

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

  static _triggerChangeIdentityHandlers(AtlasChangeIdentity? changeIdentity,
      [AtlasChangeIdentityHandler? customHandler]) {
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
      String? atlasId = preferences.getString(_storageAtlasId(appId));
      String? userDataStr = preferences.getString(_storageUserData(appId));

      // If user was authenticated while settings were loading, we assume that SDK was already reloaded
      if (_atlasId == null) {
        if (atlasId != null) {
          _atlasId = atlasId;
          if (userDataStr != null) {
            try {
              _lastIdentifiedUser = Map<String, dynamic>.from(jsonDecode(userDataStr));
            } catch (e) {
              _log("AtlasSupportSDK: Failed to parse stored user data");
              _lastIdentifiedUser = null;
            }
          }
          _triggerChangeIdentityHandlers(AtlasChangeIdentity(atlasId));
        }
      }
    } catch (error) {
      _triggerChangeIdentityHandlers(null);
      _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Failed to set Atlas ID", error));
      _lastIdentifiedUser = null;
    }
  }

  static Future<void> _setAtlasId(String atlasId, AtlasChangeIdentityHandler? onChange) async {
    var appId = _appId;
    if (appId == null || appId == "") {
      var errorMessage = "AtlasSupportSDK: Cannot change Atlas ID without App ID set";
      _triggerErrorHandlers(AtlasError(errorMessage));
      throw Exception(errorMessage);
    }

    if (_atlasId == atlasId) return;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageAtlasId(appId), atlasId);
    _atlasId = atlasId;

    _triggerChangeIdentityHandlers(AtlasChangeIdentity(atlasId), onChange);
  }

  static Future<void> _storeUserData(String appId, Map<String, dynamic> userData) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageUserData(appId), jsonEncode(userData));
      _lastIdentifiedUser = userData;
    } catch (error) {
      _log("AtlasSupportSDK: Failed to store user data");
      _log(error);
      _lastIdentifiedUser = null;
    }
  }

  static Future<void> logout() async {
    var appId = _appId;
    if (appId != null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_storageAtlasId(appId));
        await preferences.remove(_storageUserData(appId));
      } catch (error) {
        _log("AtlasSupportSDK: Failed to clear stored data");
        _log(error);
      }
    }
    _atlasId = null;
    _lastIdentifiedUser = null;
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

    // Check if user data has changed
    final newUserData = {
      'userId': userId,
      'userHash': userHash,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'customFields': customFields,
    };

    // Deep compare maps and lists in custom fields
    bool hasChanged = _lastIdentifiedUser == null || !_areMapsEqual(_lastIdentifiedUser, newUserData);
    if (!hasChanged) return;

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

      // Store the new user data after successful login
      await _storeUserData(appId, newUserData);

      if (_atlasId != atlasId) {
        await _setAtlasId(atlasId, onChange);
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

    // Get and validate userId from last identified user data
    var userIdValue = _lastIdentifiedUser?['userId'];
    if (userIdValue == null || userIdValue is! String) {
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

    // Get and validate userHash from last identified user data
    var userHashValue = _lastIdentifiedUser?['userHash'];
    String? userHash;
    if (userHashValue != null) {
      if (userHashValue is! String) {
        var errorMessage = "AtlasSupportSDK: Invalid userHash type. Expected String or null, got ${userHashValue.runtimeType}";
        _triggerErrorHandlers(AtlasError(errorMessage));
        throw Exception(errorMessage);
      }
      userHash = userHashValue;
    }
    await updateAtlasCustomFields(userIdValue, ticketId, customFields, userHash: userHash);
  }

  static watchStats(AtlasWatcherStatsChangeHandler callback, [AtlasWatcherErrorHandler? onError]) {
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

      unsubscribe = watchAtlasSupportStats(
          appId: appId,
          atlasId: atlasId,
          onStatsChange: callback,
          onError: (error) =>
              _triggerErrorHandlers(AtlasError("AtlasSupportSDK: WebSocket thrown an error", error), onError));
    }

    if (atlasId != null) subscribe(atlasId);

    void restart(AtlasChangeIdentity? identity) {
      dispose?.call();
      callback(AtlasConversationsStats(conversations: []));
      if (identity != null) subscribe(identity.atlasId);
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

    // Get userId and userHash from last identified user data
    String? userId;
    String? userHash;
    if (_lastIdentifiedUser != null) {
      userId = _lastIdentifiedUser!['userId'] as String?;
      userHash = _lastIdentifiedUser!['userHash'] as String?;
    }

    return DynamicAtlasSupportWidget(
      appId: appId,
      query: query,
      initialUserId: userId,
      initialUserHash: userHash,
      onError: (error) {
        _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Widget reported error", error), onError);
      },
      onChatStarted: (Map<String, dynamic> data) {
        var ticketId = data['ticketId'];
        var chatbotKey = data['chatbotKey'];
        if (ticketId is String) {
          var chatStarted = AtlasChatStarted(ticketId, chatbotKey);
          _triggerChatStartedHandlers(chatStarted, onChatStarted);
        } else {
          _triggerErrorHandlers(AtlasError("AtlasSupportSDK: Received invalid chat data ($data)"), onError);
        }
      },
      onNewTicket: (Map<String, dynamic> data) {
        var ticketId = data['ticketId'];
        var chatbotKey = data['chatbotKey'];
        if (ticketId is String) {
          var newTicket = AtlasNewTicket(ticketId, chatbotKey);
          _triggerNewTicketHandlers(newTicket, onNewTicket);
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
