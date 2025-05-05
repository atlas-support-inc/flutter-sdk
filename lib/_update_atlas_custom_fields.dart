import 'dart:convert';
import 'package:http/http.dart' as http;

import '_config.dart';

Future<void> updateAtlasCustomFields(
    String atlasId, String ticketId, Map<String, dynamic> customFields,
    {String? userHash}) async {
  await http.post(
    Uri.parse(
        '$atlasApiBaseUrl/client-app/ticket/$atlasId/update_custom_fields'),
    headers: {
      if (userHash != null) 'x-atlas-user-hash': userHash,
      'Content-Type': 'application/json',
    },
    body:
        json.encode({'customFields': customFields, 'conversationId': ticketId}),
  );
}
