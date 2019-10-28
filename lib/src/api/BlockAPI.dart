import 'package:veatre/common/globals.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/storage/configStorage.dart';

class BlockAPI {
  static Future<Block> best({Network network}) async {
    final net = Config.net(network: network ?? Globals.network);
    Map<dynamic, dynamic> json = await net.getBlock();
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number, {Network network}) async {
    final net = Config.net(network: network ?? Globals.network);
    Map<dynamic, dynamic> json = await net.getBlock(revision: number);
    return Block.fromJSON(json);
  }
}
