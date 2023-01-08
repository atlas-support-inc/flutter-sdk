import 'dart:convert';
import 'package:http/http.dart' as http;
import '_config.dart';

const loginUrl = "$atlasApiBaseUrl/client-app/company/identify";

Future login(
    {required String appId,
    required String userId,
    required String userHash,
    String? userName,
    String? userEmail}) {
  var uri = Uri.parse(loginUrl);

  return http
      .post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'appId': appId,
            'userId': userId,
            'userHash': userHash,
            ...(userName == null ? {} : {'userName': userName}),
            ...(userEmail == null ? {} : {'userEmail': userEmail}),
          }))
      .then(
    (response) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      throw Error(); // Login failed
    },
  );
}
