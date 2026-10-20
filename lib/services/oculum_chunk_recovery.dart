import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A timed-out pooled HTTP request can keep its connection occupied. Recover
/// only an idempotent sheet chunk on a fresh, bounded connection, with the same
/// authenticated session and database authorization as the original RPC.
Future<Object?> oculumRecoverSheetChunk({
  required String restUrl,
  required Map<String, String> headers,
  required String accessToken,
  required Map<String, dynamic> parameters,
  http.Client Function()? clientFactory,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (accessToken.isEmpty || parameters['p_event'] != 'sheet_shared_chunk') {
    throw ArgumentError('Authenticated sheet chunk required');
  }
  final client = clientFactory?.call() ?? http.Client();
  try {
    final response = await client
        .post(
          Uri.parse('$restUrl/rpc/oculum_emit_room_event'),
          headers: {
            ...headers,
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(parameters),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Sheet chunk RPC HTTP ${response.statusCode}');
    }
    return jsonDecode(response.body);
  } finally {
    // Also cancels the fresh connection when its timeout expires.
    client.close();
  }
}
