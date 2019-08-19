import 'package:sqflite/sqflite.dart';
import 'package:veatre/src/storage/database.dart';
import 'package:veatre/src/storage/networkStorage.dart';

enum IconType {
  icon,
  shortcutIcon,
  maskIcon,
  metaImage,
}

class Favicon {
  IconType type;
  String url;

  Favicon({String type, String url}) {
    IconType iconType;
    switch (type) {
      case 'icon':
        iconType = IconType.icon;
        break;
      case 'shortcut icon':
        iconType = IconType.shortcutIcon;
        break;
      case 'Shortcut Icon':
        iconType = IconType.shortcutIcon;
        break;
      case 'mask-icon':
        iconType = IconType.maskIcon;
        break;
      case 'meta':
        iconType = IconType.metaImage;
        break;
    }
    this.type = iconType;
    this.url = url;
  }
}

class BookmarkStorage {
  static Future<void> insert(Bookmark bookmark) async {
    final db = await database;
    await db.insert(
      bookmarkTableName,
      bookmark.encoded,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update(
      activityTableName,
      values,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete(
      activityTableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<List<Bookmark>> queryAll(Network network) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      bookmarkTableName,
      where: 'net = ?',
      whereArgs: [network == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return List.from(rows.map((row) => Bookmark.fromJSON(row)));
  }
}

class Bookmark {
  int id;
  String url;
  String title;
  String favicon;
  int net;

  Bookmark({
    this.id,
    this.url,
    this.title,
    this.favicon,
    this.net,
  });

  Map<String, dynamic> get encoded {
    return {
      'url': url ?? '',
      'title': title ?? '',
      'favicon': favicon ?? '',
      'net': net,
    };
  }

  factory Bookmark.fromJSON(Map<String, dynamic> parsedJSON) {
    return Bookmark(
      id: parsedJSON['id'],
      url: parsedJSON['url'],
      title: parsedJSON['title'],
      favicon: parsedJSON['favicon'],
      net: parsedJSON['net'],
    );
  }
}
