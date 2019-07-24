import 'dart:core';
import 'package:veatre/common/net.dart';
import 'package:veatre/src/models/block.dart';

const bool _isReleaseMode = const bool.fromEnvironment('dart.vm.product');

Block mainGenesis = Block.fromJSON({
  "number": 0,
  "id": "0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a",
  "size": 170,
  "parentID":
      "0xffffffff53616c757465202620526573706563742c20457468657265756d2100",
  "timestamp": 1530316800,
  "gasLimit": 10000000,
  "beneficiary": "0x0000000000000000000000000000000000000000",
  "gasUsed": 0,
  "totalScore": 0,
  "txsRoot":
      "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
  "txsFeatures": 0,
  "stateRoot":
      "0x09bfdf9e24dd5cd5b63f3c1b5d58b97ff02ca0490214a021ed7d99b93867839c",
  "receiptsRoot":
      "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
  "signer": "0x0000000000000000000000000000000000000000",
  "isTrunk": true,
  "transactions": []
});

Block testGenesis = Block.fromJSON({
  "number": 0,
  "id": "0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127",
  "size": 170,
  "parentID":
      "0xffffffff00000000000000000000000000000000000000000000000000000000",
  "timestamp": 1530014400,
  "gasLimit": 10000000,
  "beneficiary": "0x0000000000000000000000000000000000000000",
  "gasUsed": 0,
  "totalScore": 0,
  "txsRoot":
      "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
  "txsFeatures": 0,
  "stateRoot":
      "0x4ec3af0acbad1ae467ad569337d2fe8576fe303928d35b8cdd91de47e9ac84bb",
  "receiptsRoot":
      "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
  "signer": "0x0000000000000000000000000000000000000000",
  "isTrunk": true,
  "transactions": []
});

class _Driver {
  static _Driver _singleton;
  Block genesis = _isReleaseMode ? mainGenesis : testGenesis;
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
    return _net.getBlock();
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
