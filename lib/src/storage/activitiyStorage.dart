import 'package:sqflite/sqflite.dart';
import 'package:veatre/src/storage/database.dart';

class ActivityStorage {
  static Future<void> insert(Activity activity) async {
    final Database db = await database;
    await db.insert(
      activityTableName,
      activity.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Activity activity) async {
    final db = await database;
    await db.update(
      activityTableName,
      activity.encoded,
      where: "id = ?",
      whereArgs: [activity.id],
    );
  }

  static Future<List<Activity>> queryPendings() async {
    final Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      where: 'status = ?',
      whereArgs: [ActivityStatus.Pending.index],
    );
    print('rows $rows');
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }

  static Future<List<Activity>> query(
    int offset,
    int limit,
  ) async {
    final Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      orderBy: 'timestamp desc',
      offset: offset,
      limit: limit,
    );
    print('rows $rows');
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }
}

enum ActivityType {
  Transaction,
  Certificate,
}

enum ActivityStatus {
  Pending,
  Finished,
  Reverted,
}

class Activity {
  int id;
  String hash;
  String content;
  String link;
  String walletName;
  ActivityType type;
  String comment;
  int timestamp;
  ActivityStatus status; // 0 pending 1 finished 2 reverted

  Activity({
    this.id,
    this.hash,
    this.content,
    this.link,
    this.walletName,
    this.type,
    this.comment,
    this.timestamp,
    this.status,
  });

  Map<String, dynamic> get encoded {
    return {
      'hash': hash,
      'content': content,
      'link': link,
      'walletName': walletName,
      'type': type.index,
      'comment': comment,
      'timestamp': timestamp,
      'status': status.index,
    };
  }

  factory Activity.fromJSON(Map<String, dynamic> parsedJSON) {
    print("parsedJSON $parsedJSON");
    return Activity(
      id: parsedJSON['id'],
      hash: parsedJSON['hash'],
      content: parsedJSON['content'],
      link: parsedJSON['link'],
      walletName: parsedJSON['walletName'],
      type: parsedJSON['type'] == ActivityType.Transaction.index
          ? ActivityType.Transaction
          : ActivityType.Certificate,
      comment: parsedJSON['comment'],
      timestamp: parsedJSON['timestamp'],
      status: parsedJSON['status'] == ActivityStatus.Pending.index
          ? ActivityStatus.Pending
          : parsedJSON['status'] == ActivityStatus.Finished.index
              ? ActivityStatus.Finished
              : ActivityStatus.Reverted,
    );
  }
}
