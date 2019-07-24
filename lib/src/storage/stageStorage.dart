import 'package:sqflite/sqflite.dart';
import 'package:veatre/src/storage/database.dart';

class StageStorage {
  static Future<void> insert(Stage stage) async {
    final Database db = await database;
    await db.insert(
      stageTableName,
      stage.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Stage stage) async {
    final db = await database;
    await db.update(
      stageTableName,
      stage.encoded,
      where: "id = ?",
      whereArgs: [stage.id],
    );
  }

  static Future<List<Stage>> queryAll() async {
    final Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      stageTableName,
      orderBy: 'id desc',
    );
    print('rows $rows');
    return List.from(rows.map((row) => Stage.fromJSON(row)));
  }
}

class Stage {
  int id;
  String head;
  int tabID;

  Stage({
    this.id,
    this.head,
    this.tabID,
  });

  Map<String, dynamic> get encoded {
    return {
      'head': head,
      'tabID': tabID,
    };
  }

  factory Stage.fromJSON(Map<String, dynamic> parsedJSON) {
    print("parsedJSON $parsedJSON");
    return Stage(
      id: parsedJSON['id'],
      head: parsedJSON['head'],
      tabID: parsedJSON['tabID'],
    );
  }
}
