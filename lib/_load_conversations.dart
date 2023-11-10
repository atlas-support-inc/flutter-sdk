import 'dart:convert';
import 'package:http/http.dart' as http;
import '_config.dart';

Future<List<dynamic>> loadConversations(
    {required String atlasId, required String userHash}) {
  var uri = Uri.parse("$atlasApiBaseUrl/client-app/conversations/$atlasId");

  return http.get(uri, headers: {'x-atlas-user-hash': userHash}).then(
    (response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['data'] ?? {};
      }

      var text = response.body;

      try {
        var body = jsonDecode(text);
        var errorMessage = 
          body is Map && 
          body.containsKey('detail') && 
          body['detail'] is String
            ? body['detail']
            : jsonEncode(body);

        throw Exception("Stats failed: $errorMessage");
      } catch (err) {}

      throw Exception("Stats failed: HTTP(${response.statusCode}) $text");
    },
  );
}
