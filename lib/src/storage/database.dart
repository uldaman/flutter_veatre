import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final activityTableName = 'activity';

final dbName = 'storage.db';
final Future<Database> database = (() async {
  return openDatabase(
    join(await getDatabasesPath(), dbName),
    onCreate: (db, version) async {
      await db.execute(
        '''CREATE TABLE $activityTableName (id INTEGER PRIMARY KEY, hash TEXT, content TEXT, link TEXT, walletName TEXT,type INTEGER,comment TEXT, timestamp INTEGER, status INTEGER);
        ''',
      );
    },
    version: 1,
  );
})();
