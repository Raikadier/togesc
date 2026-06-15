import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note_data.dart';
import 'progress_repository.dart';

const String userProgressTable = 'user_progress';

/// Persistencia remota del progreso SRS en Supabase Postgres (RLS).
class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository({
    required SupabaseClient client,
    required String userId,
  })  : _client = client,
        _userId = userId;

  final SupabaseClient _client;
  final String _userId;

  @override
  Future<Map<String, NoteData>?> load() async {
    try {
      final row = await _client
          .from(userProgressTable)
          .select('progress')
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) return null;

      final progress = row['progress'];
      if (progress is! Map<String, dynamic>) return null;
      return parseProgressPayload(progress);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> loadLastSessionIso() async {
    try {
      final row = await _client
          .from(userProgressTable)
          .select('last_session, progress')
          .eq('user_id', _userId)
          .maybeSingle();
      if (row == null) return null;

      final fromColumn = row['last_session'];
      if (fromColumn is String && fromColumn.isNotEmpty) {
        return fromColumn;
      }
      final progress = row['progress'];
      if (progress is Map<String, dynamic>) {
        return progress['last_session'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, NoteData> noteData, {String? lastSession}) async {
    try {
      final session = lastSession ?? DateTime.now().toIso8601String();
      final payload = encodeProgressPayload(noteData, lastSession: session);
      await _client.from(userProgressTable).upsert({
        'user_id': _userId,
        'progress': payload,
        'last_session': session,
      });
    } catch (_) {
      // Sync remoto no debe bloquear el juego offline-first.
    }
  }
}
