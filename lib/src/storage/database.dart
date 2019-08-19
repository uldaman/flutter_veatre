import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final activityTableName = 'activity';
final bookmarkTableName = 'bookmark';
final dbName = 'storage.db';

final Future<Database> database = (() async {
  return openDatabase(
    join(await getDatabasesPath(), dbName),
    onCreate: (db, version) async {
      await db.execute(
        '''CREATE TABLE $activityTableName (id INTEGER PRIMARY KEY, hash TEXT,block INTEGER,processBlock INTEGER,  content TEXT, link TEXT, walletName TEXT,type INTEGER,comment TEXT, timestamp INTEGER, status INTEGER ,net INTEGER);
        ''',
      );
      await db.execute(
        '''CREATE TABLE $bookmarkTableName (id INTEGER PRIMARY KEY, url TEXT,title TEXT,favicon TEXT, net INTEGER);
        ''',
      );
    },
    version: 1,
  );
})();
