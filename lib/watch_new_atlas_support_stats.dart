library atlas_support_sdk;

import 'dart:convert';

import '_connect_customer.dart';
import '_load_conversations.dart';
import 'atlas_stats.dart';
import 'conversation_stats.dart';

typedef AtlasNewStatsChangeCallback = void Function(AtlasStats stats);
typedef AtlasNewWatcherErrorHandler = void Function(dynamic message);

Function watchNewAtlasSupportStats(
    {required String appId,
    required String atlasId,
    AtlasNewWatcherErrorHandler? onError,
    required AtlasNewStatsChangeCallback onStatsChange}) {
  Function? unsubscribe;

  var stats = AtlasStats(conversations: []);

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
                var conversation = stats.conversations.firstWhere((c) => c.id == message['conversationId']);
                conversation.unread++;
              } catch (e) {
                stats.conversations.add(ConversationsStats(id: message['conversationId'], unread: 1, closed: false));
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
  return ConversationsStats(id: conversation['id'], unread: unread, closed: conversation['closed'] == true);
}
