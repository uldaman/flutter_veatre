import "package:flutter/foundation.dart";
import "package:dio/dio.dart";

final testnet = "https://sync-testnet.vechain.org";
final genesisTime = 1530014400;
final interval = 10;

class BadParameter implements Exception {
  final String msg;

  const BadParameter(this.msg);

  String toString() {
    return "BadParameter: ${this.msg}";
  }
}

@immutable
class Vechain {
  final dio = Dio();

  dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => _getAccount(args[1]),
      "getAccountCode": () => _getAccountCode(args[1]),
      "getAccountStorage": () => _getAccountStorage(args[1], args[2]),
      "getBlock": () => _getBlock(args[1]),
      "getTransaction": () => _getTransaction(args[1]),
      "getTransactionReceipt": () => _getTransactionReceipt(args[1]),
    };

    if (methodMap.containsKey(args[0])) {
      return methodMap[args[0]]();
    }
  }

  Future<Map<String, dynamic>> status() async {
    var fn = (time) => (time - genesisTime) ~/ interval;
    dynamic block = await _getBlock("best");
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      "progress": fn(block["timestamp"]) / fn(now),
      "head": {
        "id": block["id"],
        "number": block["number"],
        "timestamp": block["timestamp"],
        "parentID": block["parentID"],
      }
    };
  }

  dynamic _getBlock(dynamic revision) async {
    Response response = await dio.get("$testnet/blocks/$revision");
    return response.data;
  }

  dynamic _getTransaction(String txId) async {
    Response response = await dio.get("$testnet/transactions/$txId");
    return response.data;
  }

  dynamic _getTransactionReceipt(String txId) async {
    Response response = await dio.get("$testnet/transactions/$txId/receipt");
    return response.data;
  }

  dynamic _getAccount(String address) async {
    Response response = await dio.get("$testnet/accounts/$address");
    return response.data;
    // throw BadParameter("'addr' expected address type");
  }

  dynamic _getAccountCode(String address) async {
    Response response = await dio.get("$testnet/accounts/$address/code");
    return response.data;
  }

  dynamic _getAccountStorage(String address, String key) async {
    Response response =
        await dio.get("$testnet/accounts/$address/Storage/$key");
    return response.data;
  }
}
