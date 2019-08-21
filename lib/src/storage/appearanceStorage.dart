import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum Appearance {
  light,
  dark,
}

class AppearanceStorage {
  static final _light = 'light';
  static final _dark = 'dark';

  static final _storage = new FlutterSecureStorage();
  static final appearanceKey =
      "9aeef72f66f72a93610d89bc3bd9502a"; // md5(appearance)

  static Future<void> set(Appearance appearance) async {
    if (appearance == Appearance.light) {
      await _storage.write(
        key: appearanceKey,
        value: _light,
      );
    } else {
      await _storage.write(
        key: appearanceKey,
        value: _dark,
      );
    }
  }

  static Future<Appearance> get appearance async {
    String appearance = await _storage.read(key: appearanceKey);
    if (appearance == null) {
      await _storage.write(
        key: appearanceKey,
        value: _light,
      );
      return Appearance.light;
    }
    return appearance == _light ? Appearance.light : Appearance.dark;
  }
}
