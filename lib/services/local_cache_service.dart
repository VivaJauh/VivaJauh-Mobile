import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_db.dart';

class LocalCacheService {
  const LocalCacheService();

  Future<void> putJson(String key, Object? value) async {
    final db = await LocalDb.open();
    await db.insert('app_cache', {
      'cache_key': key,
      'value_json': jsonEncode(value),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<T?> getJson<T>(String key) async {
    final db = await LocalDb.open();
    final rows = await db.query(
      'app_cache',
      columns: ['value_json'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['value_json'] as String) as T;
  }
}
