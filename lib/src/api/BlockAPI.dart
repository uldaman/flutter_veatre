import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class BlockAPI {
  static Future<Block> best() async {
    final net = await NetworkStorage.net;
    Map<dynamic, dynamic> json = await net.getBlock();
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number) async {
    final net = await NetworkStorage.net;
    Map<dynamic, dynamic> json = await net.getBlock(revision: number);
    return Block.fromJSON(json);
  }
}
