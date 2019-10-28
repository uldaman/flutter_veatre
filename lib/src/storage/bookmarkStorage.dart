import 'package:sqflite/sqflite.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/storage/database.dart';
import 'package:veatre/src/storage/configStorage.dart';

class BookmarkStorage {
  static Future<void> insert(Bookmark bookmark) async {
    final db = await Storage.instance;
    await db.insert(
      bookmarkTableName,
      bookmark.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(int id, Map<String, dynamic> values) async {
    final db = await Storage.instance;
    await db.update(
      bookmarkTableName,
      values,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await Storage.instance;
    await db.delete(
      bookmarkTableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<List<Bookmark>> queryAll({Network network}) async {
    final db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      bookmarkTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return List.from(rows.map((row) => Bookmark.fromJSON(row)));
  }

  static Future<Bookmark> queryByURL(String url, {Network network}) async {
    final db = await Storage.instance;
    List<Map<String, dynamic>> rows = await db.query(
      bookmarkTableName,
      where: 'network = ? and url = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1, url],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return Bookmark.fromJSON(rows.first);
  }
}

class Bookmark {
  int id;
  String url;
  String title;
  String favicon;
  Network network;

  Bookmark({
    this.id,
    this.url,
    this.title,
    this.favicon,
    this.network,
  });

  Map<String, dynamic> get encoded {
    return {
      'url': url ?? '',
      'title': title ?? '',
      'favicon': favicon ?? '',
      'network': network == Network.MainNet ? 0 : 1,
    };
  }

  factory Bookmark.fromJSON(Map<String, dynamic> parsedJSON) {
    return Bookmark(
      id: parsedJSON['id'],
      url: parsedJSON['url'],
      title: parsedJSON['title'],
      favicon: parsedJSON['favicon'],
      network: parsedJSON['network'] == 0 ? Network.MainNet : Network.TestNet,
    );
  }

  factory Bookmark.fromMeta(Map<String, dynamic> meta, Network network) {
    return Bookmark(
      url: meta['url'],
      title: meta['title'],
      favicon: meta['icon'],
      network: network,
    );
  }
}

class DocumentMetaData {
  String url;
  String title;
  String icon;

  DocumentMetaData({this.url, this.title, this.icon});

  factory DocumentMetaData.fromJSON(Map<String, dynamic> parsedJSON) {
    return DocumentMetaData(
      icon: parsedJSON['icon'],
      title: parsedJSON['title'],
      url: parsedJSON['url'],
    );
  }
}
