import 'package:veatre/src/models/block.dart';
import 'package:veatre/common/vechain.dart';

class BlockAPI {
  static Future<Block> best() async {
    Map<dynamic, dynamic> json = await Vechain.getBlock('best');
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number) async {
    Map<dynamic, dynamic> json = await Vechain.getBlock(number);
    return Block.fromJSON(json);
  }
}
