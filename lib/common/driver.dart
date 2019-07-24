import 'dart:core';
import 'package:veatre/common/net.dart';

const bool _isReleaseMode = const bool.fromEnvironment('dart.vm.product');

BlockHead mainGenesis = BlockHead.fromJSON({
  "id": "0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a",
  "number": 0,
  "timestamp": 1530316800,
  "parentID":
      "0xffffffff53616c757465202620526573706563742c20457468657265756d2100",
});
BlockHead testGenesis = BlockHead.fromJSON({
  "id": "0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127",
  "number": 0,
  "timestamp": 1530014400,
  "parentID":
      "0xffffffff00000000000000000000000000000000000000000000000000000000",
});

class BlockHead {
  String id;
  int number;
  int timestamp;
  String parentID;

  BlockHead({
    this.id,
    this.number,
    this.timestamp,
    this.parentID,
  });

  factory BlockHead.fromJSON(Map<String, dynamic> parsedJSON) {
    return BlockHead(
      id: parsedJSON['id'],
      number: parsedJSON['number'],
      timestamp: parsedJSON['timestamp'],
      parentID: parsedJSON['parentID'],
    );
  }

  get encoded => {
        "id": id,
        "number": number,
        "timestamp": timestamp,
        "parentID": parentID,
      };
}

class _Driver {
  static _Driver _singleton;
  BlockHead genesis = _isReleaseMode ? mainGenesis : testGenesis;
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

  Future<Map<String, dynamic>> get head async {
    Map<String, dynamic> block = await _net.getBlock();
    return {
      "id": block["id"],
      "number": block["number"],
      "timestamp": block["timestamp"],
      "parentID": block["parentID"],
    };
  }

  dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => _net.getAccount(args[1], revision: args[2]),
      "getCode": () => _net.getCode(args[1], revision: args[2]),
      "getStorage": () => _net.getStorage(args[1], args[2], revision: args[3]),
      "getBlock": () => _net.getBlock(revision: args[1]),
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
