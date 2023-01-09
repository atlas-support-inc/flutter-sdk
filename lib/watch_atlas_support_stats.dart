library atlas_support_sdk;

import 'dart:convert';

import 'package:atlas_support_sdk/_connect_customer.dart';
import 'package:atlas_support_sdk/_load_conversations.dart';

import '_login.dart';

Function watchAtlasSupportStats(
    {required String appId,
    required String userId,
    required String userHash,
    String? userName,
    String? userEmail,
    required Function onStatsChange}) {
  var killed = false;
  Function? unsubscribe;

  login(appId: appId, userId: userId, userHash: userHash, userName: userName, userEmail: userEmail).then((customer) {
    if (killed) throw Error(); // Canceled
    return loadConversations(atlasId: customer['id'], userHash: userHash)
        .then((conversations) => [customer, conversations]);
  }).then((results) {
    if (killed) return;

    var customer = results[0];
    var conversations = results[1];

    var stats = {
      'conversations': conversations.map(getConversationStats).toList()
    };

    onStatsChange(stats);

    void updateConversationStats(conversation) {
      var conversationStats = getConversationStats(conversation);
      var conversationIndex = stats['conversations']
          .indexWhere((c) => c['id'] == conversation['id']);
      if (conversationIndex == -1) {
        stats['conversations'].add(conversationStats);
      } else {
        stats['conversations'][conversationIndex] = conversationStats;
      }
      onStatsChange(stats);
    }

    unsubscribe = connectCustomer(
        customerId: customer['id'],
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
                  stats['conversations'] = stats['conversations']
                    .map((c) => c['id'] == data['payload']['conversationId'] ? { ...c, 'unread': 0 } : c)
                    .toList();
                  onStatsChange(stats);
                }
                break;
              case 'CHATBOT_WIDGET_RESPONSE':
                var message = jsonDecode(data['payload']['message']);
                if (!message) return;

                var conversation = stats['conversations'].firstWhere((c) => c['id'] == message['conversationId']);
                if (conversation) {
                  conversation['unread']++;
                } else {
                  stats['conversations'].add({
                    'id': message['conversationId'],
                    'unread': 1,
                    'closed': false,
                  });
                }

                onStatsChange(stats);
                break;
              case 'CONVERSATION_HIDDEN':
                stats['conversations'] = stats['conversations']
                  .where((c) => c['id'] != data['payload']['conversationId'])
                  .toList();
                onStatsChange(stats);
                break;
            }
          } catch (e) {
            return;
          }
        });
  });
  // TODO: Catch rejection and call onError()

  return () {
    killed = true;
    unsubscribe?.call();
  };
}

Map getConversationStats(conversation) {
  List messages = conversation['messages'];
  int unread = 0;
  messages.forEach((message) {
    if (!message['read']) unread++;
  });
  return {
    'id': conversation['id'],
    'unread': unread,
    'closed': conversation['closed'] == true,
  };
}
