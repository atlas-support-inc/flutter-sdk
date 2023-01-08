import 'dart:convert';
import 'package:http/http.dart' as http;
import '_config.dart';


Future loadConversations({required String atlasId, required String userHash}) {
  var uri = Uri.parse("$atlasApiBaseUrl/client-app/conversations/$atlasId");

  return http.get(uri, headers: {'x-atlas-user-hash': userHash})
    .then(
    (response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body)['data'];
      }

      throw Error(); // Stats loading failed
    },
  );
}
