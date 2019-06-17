import 'package:veatre/src/models/block.dart';
import 'package:veatre/common/net.dart';

class BlockAPI {
  static final net = Net(network: testnet);
  static Future<Block> best() async {
    Map<dynamic, dynamic> json = await net.getBlock('best');
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number) async {
    Map<dynamic, dynamic> json = await net.getBlock(number);
    return Block.fromJSON(json);
  }
}
