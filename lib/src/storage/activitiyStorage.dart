import 'package:sqflite/sqflite.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/storage/configStorage.dart';

class ActivityStorage {
  static Future<void> insert(Activity activity, {Network network}) async {
    activity.network = network ?? Globals.network;
    await Storage.insert(
      activityTableName,
      activity.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(int id, Map<String, dynamic> values) async {
    await Storage.update(
      activityTableName,
      values,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> updateHasShown() async {
    await Storage.update(
      activityTableName,
      {'hasShown': 0},
      where: 'hasShown = ?',
      whereArgs: [1],
    );
  }

  static Future<Activity> latest({Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
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
    List<Map<String, dynamic>> rows = await Storage.query(
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
    List<Map<String, dynamic>> rows = await Storage.query(
      activityTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'timestamp desc',
    );
    return List.from(rows.map((row) => Activity.fromJSON(row)));
  }

  static Future<List<Activity>> query(String address, {Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
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

  static Future<void> sync(BlockHeadForNetwork blockHeadForNetwork) async {
    int headNumber = blockHeadForNetwork.head.number;
    List<Activity> activities = await ActivityStorage.queryPendings(
      network: blockHeadForNetwork.network,
    );
    final net = Config.net(network: blockHeadForNetwork.network);
    List<Map<String, dynamic>> results = [];
    for (Activity activity in activities) {
      if (activity.type == ActivityType.Transaction) {
        String txID = activity.hash;
        Map<String, dynamic> receipt = await net.getReceipt(txID);
        Map<String, dynamic> result = {
          'activity': activity,
          'receipt': receipt,
        };
        results.add(result);
      }
    }
    await Storage.inTransaction((transaction) async {
      final batch = transaction.batch();
      for (Map<String, dynamic> result in results) {
        final receipt = result['receipt'];
        final activity = result['activity'];
        if (receipt != null) {
          int processBlock = receipt['meta']['blockNumber'];
          if (activity.processBlock == null) {
            batch.update(
              activityTableName,
              {
                'processBlock': processBlock,
                'status': ActivityStatus.Confirming.index,
              },
              where: "id = ?",
              whereArgs: [activity.id],
            );
          }
          bool reverted = receipt['reverted'];
          if (reverted) {
            batch.update(
              activityTableName,
              {'status': ActivityStatus.Reverted.index},
              where: "id = ?",
              whereArgs: [activity.id],
            );
          } else if (headNumber - processBlock >= 12) {
            batch.update(
              activityTableName,
              {'status': ActivityStatus.Finished.index},
              where: "id = ?",
              whereArgs: [activity.id],
            );
          }
        } else if (headNumber - activity.block >= 18) {
          batch.update(
            activityTableName,
            {'status': ActivityStatus.Expired.index},
            where: "id = ?",
            whereArgs: [activity.id],
          );
        }
        await batch.commit(noResult: true);
      }
    });
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
