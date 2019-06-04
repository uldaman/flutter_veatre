import 'package:veatre/src/models/Block.dart';
import 'package:veatre/src/api/API.dart';

class BlockAPI {
  static Future<Block> best() async {
    Map<dynamic, dynamic> json = await API.get("/blocks/best");
    return Block.fromJSON(json);
  }

  static Future<Block> get(int number) async {
    Map<dynamic, dynamic> json = await API.get("/blocks/" + number.toString());
    return Block.fromJSON(json);
  }
}
