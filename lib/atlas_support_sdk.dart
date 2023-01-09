library atlas_support_sdk;

import 'watch_atlas_support_stats.dart';
import 'atlas_support_widget.dart';

class AtlasSupportSDK {
  final String appId;
  String userId;
  String userHash;
  String? userName;
  String? userEmail;

  AtlasSupportSDK({required this.appId, this.userId = "", this.userHash = "", this.userName, this.userEmail});

  Widget() {
    return AtlasSupportWidget(
        appId: appId, userId: userId, userHash: userHash, userName: userName, userEmail: userEmail);
  }

  watchStats(Function listener) {
    var close = watchAtlasSupportStats(
        appId: appId,
        userId: userId,
        userHash: userHash,
        onStatsChange: listener);

    return () {
      close();
    };
  }
}

AtlasSupportSDK createAtlasSupportSDK(
    String appId, String userId, String userHash) {
  return AtlasSupportSDK(appId: appId, userId: userId, userHash: userHash);
}
