import 'dart:core';
import 'package:veatre/common/net.dart';

const bool _isReleaseMode = const bool.fromEnvironment('dart.vm.product');
const mainGenesis = {
  "id": "0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a",
  "number": 0,
  "timestamp": 1530316800,
  "parentID":
      "0xffffffff53616c757465202620526573706563742c20457468657265756d2100",
};
const testGenesis = {
  "id": "0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127",
  "number": 0,
  "timestamp": 1530014400,
  "parentID":
      "0xffffffff00000000000000000000000000000000000000000000000000000000",
};

class _Driver {
  static _Driver _singleton;
  Map<String, dynamic> _head = _isReleaseMode ? mainGenesis : testGenesis;
  final Net _net;

  factory _Driver() {
    if (_singleton == null) {
      _singleton = _Driver._internal(
        _isReleaseMode ? Net(mainnet) : Net(testnet),
      );
    }
    return _singleton;
  }

  _Driver._internal(this._net);

  Map<String, dynamic> get head => _head;

  Future syncHead() {
    return _net.getBlock("best").then((block) {
      _head = {
        "id": block["id"],
        "number": block["number"],
        "timestamp": block["timestamp"],
        "parentID": block["parentID"],
      };
      return _head;
    });
  }

  dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => _net.getAccount(args[1], revision: args[2]),
      "getCode": () => _net.getCode(args[1], revision: args[2]),
      "getStorage": () => _net.getStorage(args[1], args[2], revision: args[3]),
      "getBlock": () => _net.getBlock(args[1]),
      "getTransaction": () => _net.getTransaction(args[1]),
      "getReceipt": () => _net.getReceipt(args[1]),
      "filterTransferLogs": () => _net.filterTransferLogs(args[1]),
      "filterEventLogs": () => _net.filterEventLogs(args[1]),
      "explain": () => _net.explain(args[1], revision: args[2]),
    };
    if (methodMap.containsKey(args[0])) {
      return methodMap[args[0]]();
    }
  }
}

_Driver driver = _Driver();
