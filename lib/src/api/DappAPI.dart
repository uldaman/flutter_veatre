import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/dapp.dart';

class DAppAPI {
  static Future<List<DApp>> list() async {
    dynamic data = await Net.http(
        'GET', 'https://vechain.github.io/app-hub/index.json', {});
    List<DApp> apps = [];
    for (Map<String, dynamic> app in data) {
      apps.add(DApp.fromJSON(app));
    }
    return apps;
  }
}
