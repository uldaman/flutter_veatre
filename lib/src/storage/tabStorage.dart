import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:veatre/src/storage/database.dart';

class TabStorage {
  static Future<void> inserTab(Tab tab) async {
    final Database db = await database;
    await db.insert(
      tabsTableName,
      tab.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTab(Tab tab) async {
    final db = await database;
    await db.update(
      tabsTableName,
      tab.encoded,
      where: "id = ?",
      whereArgs: [tab.id],
    );
  }

  static Future<List<Tab>> queryTabs(
    int offset,
    int limit,
  ) async {
    final Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      tabsTableName,
      orderBy: 'id desc',
      offset: offset,
      limit: limit,
    );
    print('rows $rows');
    return List.from(rows.map((row) => Tab.fromJSON(row)));
  }
}

class Tab {
  int id;
  String title;
  Uint8List data;
  String url;

  Tab({
    this.id,
    this.title,
    this.data,
    this.url,
  });

  Map<String, dynamic> get encoded {
    return {
      'title': title,
      'data': data,
      'url': url,
    };
  }

  factory Tab.fromJSON(Map<String, dynamic> parsedJSON) {
    print("parsedJSON $parsedJSON");
    return Tab(
      id: parsedJSON['id'],
      title: parsedJSON['title'],
      data: parsedJSON['data'],
      url: parsedJSON['url'],
    );
  }
}
