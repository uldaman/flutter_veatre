import 'package:veatre/common/net.dart';

class Driver {
  Net net;
  Driver(this.net);

  Future<Map<String, dynamic>> head() async {
    dynamic block = await net.getBlock("best");
    return {
      "id": block["id"],
      "number": block["number"],
      "timestamp": block["timestamp"],
      "parentID": block["parentID"],
    };
  }

  dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => net.getAccount(args[1], revision: args[2]),
      "getCode": () => net.getCode(args[1], revision: args[2]),
      "getStorage": () => net.getStorage(args[1], args[2], revision: args[3]),
      "getBlock": () => net.getBlock(args[1]),
      "getTransaction": () => net.getTransaction(args[1]),
      "getReceipt": () => net.getReceipt(args[1]),
      "filterTransferLogs": () => net.filterTransferLogs(args[1]),
      "filterEventLogs": () => net.filterEventLogs(args[1]),
      "explain": () => net.explain(args[1], revision: args[2]),
    };
    if (methodMap.containsKey(args[0])) {
      return methodMap[args[0]]();
    }
  }
}
