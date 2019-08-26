import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final configTableName = 'config';
final walletTableName = 'wallet';
final activityTableName = 'activity';
final bookmarkTableName = 'bookmark';
final dbName = 'storage.db';

final Future<Database> database = (() async {
  return openDatabase(
    join(await getDatabasesPath(), dbName),
    onCreate: (db, version) async {
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS $configTableName (id INTEGER PRIMARY KEY, theme INTEGER, network INTEGER);
        ''',
      );
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS $walletTableName (id INTEGER PRIMARY KEY, name TEXT UNIQUE, keystore TEXT, isMain INTEGER, network INTEGER);
        ''',
      );
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS $activityTableName (id INTEGER PRIMARY KEY, hash TEXT,block INTEGER,processBlock INTEGER, content TEXT, link TEXT, walletName TEXT,type INTEGER,comment TEXT, timestamp INTEGER, status INTEGER ,network INTEGER);
        ''',
      );
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS $bookmarkTableName (id INTEGER PRIMARY KEY, url TEXT,title TEXT,favicon TEXT, network INTEGER);
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
