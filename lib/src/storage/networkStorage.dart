import 'package:veatre/common/net.dart';
import 'package:veatre/src/storage/database.dart';

enum Network {
  MainNet,
  TestNet,
}

class NetworkStorage {
  static final testnet = "https://sync-testnet.vechain.org";
  static final mainnet = "https://sync-mainnet.vechain.org";

  static Future<void> set(Network network) async {
    final db = await database;
    await db.update(
        configTableName, {'network': network == Network.MainNet ? 0 : 1});
  }

  static Future<Net> net(Network network) async {
    if (network == Network.MainNet) {
      return Net(NetworkStorage.mainnet);
    }
    return Net(NetworkStorage.testnet);
  }

  static Future<Network> get network async {
    final db = await database;
    final rows = await db.query(
      configTableName,
      limit: 1,
    );
    Network network =
        rows.first['network'] == 0 ? Network.MainNet : Network.TestNet;
    return network;
  }
}
