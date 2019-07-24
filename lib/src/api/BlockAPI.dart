import 'package:veatre/src/models/block.dart';
import 'package:veatre/common/net.dart';

class BlockAPI {
  static final net = Net(testnet);
  static Future<Block> best() async {
    Map<dynamic, dynamic> json = await net.getBlock();
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number) async {
    Map<dynamic, dynamic> json = await net.getBlock(revision: number);
    return Block.fromJSON(json);
  }
}
