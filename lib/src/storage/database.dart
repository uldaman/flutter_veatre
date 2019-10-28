import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Storage {
  static Database _database;

  static Future<Database> get instance async {
    if (_database == null) {
      _database = await open;
    }
    return _database;
  }

  static Future<Database> open = (() async {
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
  })();
}

final configTableName = 'config';
final walletTableName = 'wallet';
final activityTableName = 'activity';
final bookmarkTableName = 'bookmark';
final dbName = 'storage.db';
