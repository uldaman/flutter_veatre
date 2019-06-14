import 'package:veatre/common/net.dart';

class Driver {
  Net net;
  Driver(this.net);

  dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => net.getAccount(args[1]),
      "getCode": () => net.getCode(args[1]),
      "getStorage": () => net.getStorage(args[1], args[2]),
      "getBlock": () => net.getBlock(args[1]),
      "getTransaction": () => net.getTransaction(args[1]),
      "getReceipt": () => net.getReceipt(args[1]),
    };
    if (methodMap.containsKey(args[0])) {
      return methodMap[args[0]]();
    }
  }
}
