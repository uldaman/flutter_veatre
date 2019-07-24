import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final activityTableName = 'activity';
final tabsTableName = 'tabs';
final stageTableName = 'stage';

final dbName = 'storage.db';
final Future<Database> database = (() async {
  return openDatabase(
    join(await getDatabasesPath(), dbName),
    onCreate: (db, version) async {
      await db.execute(
        '''CREATE TABLE $activityTableName (id INTEGER PRIMARY KEY, hash TEXT, content TEXT, link TEXT, walletName TEXT,type INTEGER,comment TEXT, timestamp INTEGER, status INTEGER);
        CREATE TABLE $tabsTableName (id INTEGER PRIMARY KEY, title TEXT, data blob, url TEXT);
        CREATE TABLE $stageTableName (id INTEGER PRIMARY KEY, head TEXT, tabID INTEGER);
        ''',
      );
    },
    version: 1,
  );
})();
