import 'dart:core';
import 'package:veatre/common/net.dart';

const bool _isReleaseMode = const bool.fromEnvironment('dart.vm.product');

class _Driver {
  static _Driver _singleton;
  Map<String, dynamic> _head;
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
