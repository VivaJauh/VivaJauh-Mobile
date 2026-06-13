import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> open() async {
    if (_db != null) return _db!;
    final dbPath = path.join(await getDatabasesPath(), 'vivajauh.db');
    _db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
        await _createCacheTables(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) await _dropTenantColumn(db);
        if (oldVersion < 4) await _createCacheTables(db);
        await _createIndexes(db);
      },
      onOpen: (db) async {
        await _createTables(db);
        await _createCacheTables(db);
        await _createIndexes(db);
      },
    );
    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS records(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        record_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        uploaded_at TEXT,
        error_message TEXT,
        verification_status TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCacheTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_cache(
        cache_key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _dropTenantColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(records)');
    final hasTenant = columns.any((col) => col['name'] == 'tenant_id');
    if (!hasTenant) return;
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE records_new(
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          device_id TEXT NOT NULL,
          record_type TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          sync_status TEXT NOT NULL,
          idempotency_key TEXT NOT NULL,
          recorded_at TEXT NOT NULL,
          uploaded_at TEXT,
          error_message TEXT,
          verification_status TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        INSERT INTO records_new
        SELECT id, user_id, device_id, record_type, payload_json,
               sync_status, idempotency_key, recorded_at, uploaded_at,
               error_message, verification_status
        FROM records
      ''');
      await txn.execute('DROP TABLE records');
      await txn.execute('ALTER TABLE records_new RENAME TO records');
    });
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_type ON records(record_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_sync ON records(sync_status)',
    );
  }
}
