library atlas_support_sdk;

import 'dart:convert';

import '_connect_customer.dart';
import '_load_conversations.dart';
import 'atlas_stats.dart';
import 'conversation_stats.dart';

import '_login.dart';

typedef StatsChangeCallback = void Function(AtlasStats stats);
typedef AtlasWatcherErrorHandler = void Function(dynamic message);

Function watchAtlasSupportStats(
    {required String appId,
    String? atlasId,
    String? userId,
    String? userHash,
    String? name,
    String? email,
    String? phoneNumber,
    AtlasWatcherErrorHandler? onError,
    required StatsChangeCallback onStatsChange}) {
  var killed = false;
  Function? unsubscribe;

  if (atlasId == null && userId == null) return () {};

  (atlasId != null
          ? Future.value(atlasId)
          : userId != null && userId != ""
              ? login(
                      appId: appId,
                      userId: userId,
                      userHash: userHash,
                      name: name,
                      email: email,
                      phoneNumber: phoneNumber)
                  .then((customer) => customer['id'])
              : Future.error("No credentials provided for login"))
      .then((atlasId) {
    if (killed) throw Exception("Subscription canceled at login");
    return loadConversations(atlasId: atlasId, userHash: userHash)
        .then((conversations) => [atlasId, conversations]);
  }).then((results) {
    if (killed) throw Exception("Subscription canceled");

    var atlasId = results[0];
    final conversations = results[1] as List<dynamic>;

    var conversationsStats = conversations.map(getConversationStats).toList();
    var stats = AtlasStats(conversations: conversationsStats);

    onStatsChange(stats);

    void updateConversationStats(conversation) {
      var conversationStats = getConversationStats(conversation);
      var conversationIndex =
          stats.conversations.indexWhere((c) => c.id == conversation['id']);
      if (conversationIndex == -1) {
        stats.conversations.add(conversationStats);
      } else {
        stats.conversations[conversationIndex] = conversationStats;
      }
      onStatsChange(stats);
    }

    unsubscribe = connectCustomer(
        atlasId: atlasId,
        onMessage: (packet) {
          try {
            var data = jsonDecode(packet);
            switch (data['packet_type']) {
              case 'CONVERSATION_UPDATED':
                updateConversationStats(data['payload']['conversation']);
                break;
              case 'AGENT_MESSAGE':
              case 'BOT_MESSAGE':
                var conversation = jsonDecode(data['payload']['conversation']);
                updateConversationStats(conversation);
                break;
              case 'MESSAGE_READ':
                if (data['payload']['conversationId'] is String) {
                  stats.conversations = stats.conversations.map((c) {
                    if (c.id == data['payload']['conversationId']) c.unread = 0;
                    return c;
                  }).toList();
                  onStatsChange(stats);
                }
                break;
              case 'CHATBOT_WIDGET_RESPONSE':
                var message = jsonDecode(data['payload']['message']);
                if (!message) return;

                try {
                  var conversation = stats.conversations
                      .firstWhere((c) => c.id == message['conversationId']);
                  conversation.unread++;
                } catch (e) {
                  stats.conversations.add(ConversationsStats(
                      id: message['conversationId'], unread: 1, closed: false));
                }

                onStatsChange(stats);
                break;
              case 'CONVERSATION_HIDDEN':
                stats.conversations = stats.conversations
                    .where((c) => c.id != data['payload']['conversationId'])
                    .toList();
                onStatsChange(stats);
                break;
            }
          } catch (error) {
            onError?.call(error);
            return;
          }
        });
  }).catchError((error) {
    onError?.call(error);
  });

  return () {
    killed = true;
    unsubscribe?.call();
  };
}

ConversationsStats getConversationStats(dynamic conversation) {
  List messages = conversation['messages'] ?? [];
  int unread = 0;
  for (var message in messages) {
    if (!message.containsKey('read')) continue;
    if (message['read'] == true) continue;

    if (message['side'] == messageSide['BOT']) {
      unread++;
    } else if (message['side'] == messageSide['AGENT']) {
      unread++;
    }
  }
  return ConversationsStats(
      id: conversation['id'],
      unread: unread,
      closed: conversation['closed'] == true);
}
