import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'server_config.dart';
import 'server_connection_service.dart';

class PersonChanges {
  const PersonChanges(this.cursor, this.personIds);
  final String? cursor;

  /// null requests a snapshot, an empty set means the cached page is current.
  final Set<int>? personIds;
}

class PersonChangeSource {
  PersonChangeSource(this.config, {http.Client? client, this.onUnauthorized})
    : _client = client ?? http.Client();
  final ServerConfig config;
  final http.Client _client;
  final void Function()? onUnauthorized;
  bool _unsupported = false;

  Future<PersonChanges> read({
    required String? cursor,
    required Iterable<int> knownIds,
    required String domain,
  }) async {
    if (!config.isServerMode || _unsupported) {
      return const PersonChanges(null, null);
    }
    final response = await _client
        .post(
          Uri.parse('${config.normalizedBaseUrl}/api/storage/person-changes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.jwtToken}',
          },
          body: jsonEncode({
            'cursor': cursor,
            'knownPersonIds': knownIds.toList(),
            'domain': domain,
          }),
        )
        .timeout(const Duration(seconds: 30));
    // Allows a staged client/server upgrade. Transient failures must keep the
    // cursor so an unsuccessful refresh never silently drops pending changes.
    if (response.statusCode == 404) {
      _unsupported = true;
      return const PersonChanges(null, null);
    }
    if (response.statusCode != 200) {
      if (response.statusCode == 401) onUnauthorized?.call();
      throw http.ClientException('Change sync HTTP ${response.statusCode}');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PersonChanges(
      body['cursor'] as String,
      body['resetRequired'] == true
          ? null
          : (body['personIds'] as List).cast<int>().toSet(),
    );
  }

  void close() => _client.close();
}

final personChangeSourceProvider = Provider<PersonChangeSource>((ref) {
  final source = PersonChangeSource(
    ref.watch(serverConfigProvider),
    onUnauthorized: () {
      if (ref.mounted)
        ref.read(serverConfigProvider.notifier).setJwtToken(null);
    },
  );
  ref.onDispose(source.close);
  return source;
});
