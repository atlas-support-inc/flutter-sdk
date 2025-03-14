library atlas_support_sdk;

import 'dart:convert';

import '_connect_customer.dart';

class ConversationStats {
  final String id;
  int unread;
  bool closed;

  ConversationStats({
    required this.id,
    required this.unread,
    required this.closed,
  });
}

class AtlasConversationsStats {
  List<ConversationStats> conversations;

  AtlasConversationsStats({required this.conversations});
}

typedef AtlasWatcherStatsChangeHandler = void Function(AtlasConversationsStats stats);
typedef AtlasWatcherErrorHandler = void Function(dynamic message);

Function watchAtlasSupportStats(
    {required String appId,
    required String atlasId,
    required AtlasWatcherStatsChangeHandler onStatsChange,
    AtlasWatcherErrorHandler? onError}) {
  Function? unsubscribe;

  var stats = AtlasConversationsStats(conversations: []);

  onStatsChange(stats);

  void updateConversationStats(conversation) {
    var conversationStats = getConversationStats(conversation);
    var conversationIndex = stats.conversations.indexWhere((c) => c.id == conversation['id']);
    if (conversationIndex == -1) {
      stats.conversations.add(conversationStats);
    } else {
      stats.conversations[conversationIndex] = conversationStats;
    }
    onStatsChange(stats);
  }

  unsubscribe = connectCustomer(
      atlasId: atlasId,
      onError: onError,
      onMessage: (packet) {
        try {
          var data = jsonDecode(packet);
          switch (data['packet_type']) {
            case 'CONVERSATION_UPDATED':
              updateConversationStats(data['payload']['conversation']);
              break;
            case 'AGENT_MESSAGE':
            case 'BOT_MESSAGE':
              if (data['payload'].containsKey('conversation') && data['payload']['conversation'] is String) {
                var conversation = jsonDecode(data['payload']['conversation']);
                updateConversationStats(conversation);
              }
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
                var conversation = stats.conversations.firstWhere((c) => c.id == message['conversationId']);
                conversation.unread++;
              } catch (e) {
                stats.conversations.add(ConversationStats(id: message['conversationId'], unread: 1, closed: false));
              }

              onStatsChange(stats);
              break;
            case 'CONVERSATION_HIDDEN':
              stats.conversations =
                  stats.conversations.where((c) => c.id != data['payload']['conversationId']).toList();
              onStatsChange(stats);
              break;
            case 'REFRESH_DATA':
              if (data['payload'].containsKey('conversations') && data['payload']['conversations'] is List) {
                List<dynamic> conversationsData = data['payload']['conversations'];
                for (var conversation in conversationsData) {
                  updateConversationStats(conversation);
                }
                onStatsChange(stats);
              }
              break;
          }
        } catch (error) {
          onError?.call(error);
          return;
        }
      });

  return () => unsubscribe?.call();
}

final _messageSide = {
  'CUSTOMER': 1,
  'AGENT': 2,
  'BOT': 3,
};

ConversationStats getConversationStats(dynamic conversation) {
  List messages = conversation['messages'] ?? [];
  int unread = 0;
  for (var message in messages) {
    if (!message.containsKey('read')) continue;
    if (message['read'] == true) continue;

    if (message['side'] == _messageSide['BOT']) {
      unread++;
    } else if (message['side'] == _messageSide['AGENT']) {
      unread++;
    }
  }
  return ConversationStats(id: conversation['id'], unread: unread, closed: conversation['closed'] == true);
}
