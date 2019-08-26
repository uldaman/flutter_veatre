import 'package:veatre/src/storage/database.dart';

enum Appearance {
  light,
  dark,
}

class AppearanceStorage {
  static Future<void> set(Appearance appearance) async {
    final db = await database;
    await db.update(
        configTableName, {'theme': appearance == Appearance.light ? 0 : 1});
  }

  static Future<Appearance> get appearance async {
    final db = await database;
    final rows = await db.query(
      configTableName,
    );
    return rows.first['theme'] == 0 ? Appearance.light : Appearance.dark;
  }
}
