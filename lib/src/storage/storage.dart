import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class Storage {
  static Database _database;
  static final Lock _lock = Lock(reentrant: true);

  static Future<Database> get _instance async {
    if (_database == null) {
      _database = await open();
    }
    return _database;
  }

  static Future<Database> open() async {
    if (_database != null) return _database;
    _database = await openDatabase(
      join(await getDatabasesPath(), dbName),
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS $configTableName (id INTEGER PRIMARY KEY, theme INTEGER,passwordHash TEXT, network INTEGER);
        ''',
        );
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS $walletTableName (id INTEGER PRIMARY KEY, name TEXT, address TEXT, mnemonicCipher TEXT, iv TEXT, isMain INTEGER, hasBackup INTEGER, network INTEGER);
        ''',
        );
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS $activityTableName (id INTEGER PRIMARY KEY, hash TEXT, block INTEGER, processBlock INTEGER, content TEXT, link TEXT, address TEXT,type INTEGER, comment TEXT, timestamp INTEGER, status INTEGER,network INTEGER, hasShown INTEGER);
        ''',
        );
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS $bookmarkTableName (id INTEGER PRIMARY KEY, url TEXT, title TEXT, favicon TEXT, network INTEGER);
        ''',
        );
        final rows = await db.query(
          configTableName,
        );
        if (rows.length == 0) {
          await db.insert(configTableName, {
            'theme': 0,
            'network': 0,
          });
        }
      },
      version: 1,
    );
    return _database;
  }

  static Future<T> inTransaction<T>(Future<T> action(Transaction txn)) async {
    return _lock.synchronized(() async {
      final db = await Storage._instance;
      return db.transaction(
        (transaction) async {
          return await action(transaction);
        },
        exclusive: true,
      );
    });
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    bool distinct,
    List<String> columns,
    String where,
    List<dynamic> whereArgs,
    String groupBy,
    String having,
    String orderBy,
    int limit,
    int offset,
  }) {
    return _lock.synchronized(() async {
      final db = await Storage._instance;
      return db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    });
  }

  static Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String nullColumnHack,
    ConflictAlgorithm conflictAlgorithm,
  }) {
    return _lock.synchronized(() async {
      final db = await Storage._instance;
      return db.insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm,
      );
    });
  }

  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String where,
    List<dynamic> whereArgs,
    ConflictAlgorithm conflictAlgorithm,
  }) {
    return _lock.synchronized(() async {
      final db = await Storage._instance;
      return db.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      );
    });
  }

  static Future<int> delete(
    String table, {
    String where,
    List<dynamic> whereArgs,
  }) {
    return _lock.synchronized(() async {
      final db = await Storage._instance;
      return db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
    });
  }
}

final configTableName = 'config';
final walletTableName = 'wallet';
final activityTableName = 'activity';
final bookmarkTableName = 'bookmark';
final dbName = 'storage.db';
