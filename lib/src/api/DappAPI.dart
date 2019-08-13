import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/dapp.dart';

class DappAPI {
  static Future<List<Dapp>> list() async {
    dynamic data = await Net.http(
        'GET', 'https://vechain.github.io/app-hub/index.json', {});
    List<Dapp> apps = [];
    for (Map<String, dynamic> app in data) {
      apps.add(Dapp.fromJSON(app));
    }
    return apps;
  }
}
