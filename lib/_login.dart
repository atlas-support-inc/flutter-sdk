import 'dart:convert';
import 'package:http/http.dart' as http;
import '_config.dart';

const _loginUrl = "$atlasApiBaseUrl/client-app/company/identify";

typedef AtlasCustomFields = Map<String, dynamic>;

Future login(
    {required String appId,
    required String userId,
    String? userHash,
    String? name,
    String? email,
    String? phoneNumber,
    AtlasCustomFields? customFields}) {
  var uri = Uri.parse(_loginUrl);

  return http
      .post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'appId': appId,
            'userId': userId,
            ...(userHash == null ? {} : {'userHash': userHash}),
            ...(name == null ? {} : {'name': name}),
            ...(email == null ? {} : {'email': email}),
            ...(phoneNumber == null ? {} : {'phoneNumber': phoneNumber}),
            ...(customFields == null ? {} : {'customFields': customFields}),
          }))
      .then(
    (response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      var text = response.body;

      try {
        var body = jsonDecode(text);
        var errorMessage =
            body is Map && body.containsKey('detail') && body['detail'] is String ? body['detail'] : jsonEncode(body);

        throw Exception("Login failed: $errorMessage");
      } catch (err) {}

      throw Exception("Login failed: HTTP(${response.statusCode}) $text");
    },
  );
}
