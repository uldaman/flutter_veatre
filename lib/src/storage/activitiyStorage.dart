import 'package:sqflite/sqflite.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/database.dart';
import 'package:veatre/src/storage/configStorage.dart';

class ActivityStorage {
  static Future<void> insert(Activity activity, {Network network}) async {
    final db = await Storage.instance;
    activity.network = network ?? Globals.network;
    await db.insert(
      activityTableName,
      activity.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(int id, Map<String, dynamic> values) async {
    final db = await Storage.instance;
    await db.update(
      activityTableName,
      values,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> updateHasShown() async {
    final db = await Storage.instance;
    await db.update(
      activityTableName,
      {'hasShown': 0},
      where: 'hasShown = ?',
      whereArgs: [1],
    );
  }

  static Future<Activity> latest({Network network}) async {
    final Database db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return Activity.fromJSON(rows.first);
  }

  static Future<List<Activity>> queryPendings({Network network}) async {
    final Database db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      where: 'status in (?,?) and network = ?',
      whereArgs: [
        ActivityStatus.Pending.index,
        ActivityStatus.Confirming.index,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
    );
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }

  static Future<List<Activity>> queryAll({Network network}) async {
    final db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'timestamp desc',
    );
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }

  static Future<List<Activity>> query(String address, {Network network}) async {
    final db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      activityTableName,
      where: 'address = ? and network = ?',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
      orderBy: 'timestamp desc',
    );
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }
}

enum ActivityType {
  Transaction,
  Certificate,
}

enum ActivityStatus {
  Pending,
  Confirming,
  Finished,
  Expired,
  Reverted,
}

class Activity {
  int id;
  int block;
  int processBlock;
  String hash;
  String content;
  String link;
  String address;
  ActivityType type;
  String comment;
  int timestamp;
  // 0 pending 1 confirming 2 finished 3 expired 4 reverted
  ActivityStatus status;
  Network network;
  bool hasShown;

  Activity({
    this.id,
    this.hash,
    this.block,
    this.processBlock,
    this.content,
    this.link,
    this.address,
    this.type,
    this.comment,
    this.timestamp,
    this.status,
    this.network,
    this.hasShown = false,
  });

  Map<String, dynamic> get encoded {
    return {
      'hash': hash,
      'block': block,
      'processBlock': processBlock,
      'content': content,
      'link': link,
      'address': address,
      'type': type.index,
      'comment': comment,
      'timestamp': timestamp,
      'status': status.index,
      'network': network == Network.MainNet ? 0 : 1,
      'hasShown': hasShown ? 0 : 1,
    };
  }

  factory Activity.fromJSON(Map<String, dynamic> parsedJSON) {
    return Activity(
      id: parsedJSON['id'],
      hash: parsedJSON['hash'],
      block: parsedJSON['block'],
      processBlock: parsedJSON['processBlock'],
      content: parsedJSON['content'],
      link: parsedJSON['link'],
      address: parsedJSON['address'],
      type: parsedJSON['type'] == ActivityType.Transaction.index
          ? ActivityType.Transaction
          : ActivityType.Certificate,
      comment: parsedJSON['comment'],
      timestamp: parsedJSON['timestamp'],
      status: parsedJSON['status'] == ActivityStatus.Pending.index
          ? ActivityStatus.Pending
          : parsedJSON['status'] == ActivityStatus.Confirming.index
              ? ActivityStatus.Confirming
              : parsedJSON['status'] == ActivityStatus.Finished.index
                  ? ActivityStatus.Finished
                  : parsedJSON['status'] == ActivityStatus.Reverted.index
                      ? ActivityStatus.Reverted
                      : ActivityStatus.Expired,
      network: parsedJSON['network'] == 0 ? Network.MainNet : Network.TestNet,
      hasShown: parsedJSON['hasShown'] == 0,
    );
  }
}
