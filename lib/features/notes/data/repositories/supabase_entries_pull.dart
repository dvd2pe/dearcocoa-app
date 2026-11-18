import 'dart:convert';

import 'package:dairy_app/core/databases/db_schemas.dart';
import 'package:dairy_app/core/dependency_injection/injection_container.dart';
import 'package:dairy_app/core/logger/logger.dart';
import 'package:dairy_app/features/auth/core/constants.dart';
import 'package:dairy_app/features/notes/data/datasources/local%20data%20sources/local_data_source.dart';
import 'package:dairy_app/features/sync/data/datasources/temeplates/key_value_data_source_template.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/network/supabase_client.dart';

final _log = printer("SupabaseEntriesPull");

/// Pulls the signed-in user's cloud journal entries (Supabase `entries`,
/// owner-only via RLS) into the local DiaryVault journal (sqlite `Notes`).
///
/// - Idempotent: a cloud entry id already present locally is skipped.
/// - The local note id equals the cloud entry id, so a future two-way sync
///   can upsert safely against the same key.
/// - One-way (cloud -> local) for now: local-only notes are NOT pushed back
///   in this demo build.
class SupabaseEntriesPull {
  SupabaseEntriesPull._();

  /// Serializes concurrent pulls (sign-in and hub init can both trigger it):
  /// the Notes table has no PRIMARY KEY, so two racing pulls would insert
  /// duplicates.
  static Future<void>? _inFlight;

  /// Fetches cloud entries and stores the missing ones locally (idempotent).
  /// Returns how many notes were added. Safe to call multiple times.
  static Future<int> pullIntoLocalJournal() {
    if (_inFlight != null) return _inFlight!;
    final task = _pull().whenComplete(() => _inFlight = null);
    _inFlight = task;
    return task;
  }

  static Future<int> _pull() async {
    final client = supabase;
    if (client == null) return 0;
    final user = client.auth.currentUser;
    if (user == null) return 0;

    try {
      final rows = await client
          .from('entries')
          .select()
          .eq('user_id', user.id)
          .order('entry_date', ascending: false)
          .limit(200);

      final list = rows as List<dynamic>;
      if (list.isEmpty) return 0;

      // The local journal belongs to the app user (or the guest identity).
      final kv = sl<IKeyValueDataSource>();
      final authorId = kv.getValue(Global.lastLoggedInUser) ??
          GuestUserDetails.guestUserId;

      final Database db = NotesLocalDataSource.database;
      var added = 0;

      // single transaction: consistent existence checks + inserts
      await db.transaction((txn) async {
        for (final raw in list) {
          final row = raw as Map<String, dynamic>;

          // soft-deleted cloud entries are skipped
          if (row['deleted_at'] != null) continue;

          final cloudId = row['id'] as String;
          final exists = await txn.query(
            Notes.TABLE_NAME,
            columns: [Notes.ID],
            where: "${Notes.ID} = ?",
            whereArgs: [cloudId],
            limit: 1,
          );
          if (exists.isNotEmpty) continue;

          final delta = (row['content_delta'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final plainText = _deltaToPlainText(delta);
          final createdAtMs = _isoToMs(row['created_at'] as String?);
          final updatedAtMs = _isoToMs(row['updated_at'] as String?) ??
              createdAtMs ??
              DateTime.now().millisecondsSinceEpoch;

          final noteMap = <String, dynamic>{
            Notes.ID: cloudId,
            Notes.TITLE: (row['title'] as String?) ?? '(untitled)',
            Notes.BODY: jsonEncode(delta),
            Notes.PLAIN_TEXT: plainText,
            Notes.CREATED_AT:
                createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
            Notes.LAST_MODIFIED: updatedAtMs,
            Notes.DELETED: 0,
            Notes.HASH: '',
            Notes.AUTHOR_ID: authorId,
            Notes.IS_ENCRYPTED: 0,
          };

          try {
            await txn.insert(Notes.TABLE_NAME, noteMap);
          } catch (e) {
            _log.e("failed to insert pulled note $cloudId: $e");
            continue;
          }

          // tags (same table the app writes on note save)
          for (final tag in (row['tags'] as List<dynamic>? ?? [])) {
            final name = tag.toString().trim();
            if (name.isEmpty) continue;
            await txn.insert(
              Tags.TABLE_NAME,
              {Tags.NOTE_ID: cloudId, Tags.NAME: name},
            );
          }

          added++;
        }
      });

      _log.i("pulled $added cloud entries into the local journal");
      return added;
    } catch (e) {
      _log.e("cloud journal pull failed: $e");
      return 0;
    }
  }

  /// Concatenates the plain text carried by a Quill Delta document.
  static String _deltaToPlainText(List<Map<String, dynamic>> delta) {
    final buffer = StringBuffer();
    for (final op in delta) {
      final insert = op['insert'];
      if (insert is String) buffer.write(insert);
    }
    return buffer.toString().trim();
  }

  static int? _isoToMs(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso).millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }
}
