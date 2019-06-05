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
  static final dio = Dio();

  static dynamic callMethod(List<dynamic> args) async {
    var methodMap = {
      "getAccount": () => getAccount(args[1]),
      "getAccountCode": () => getAccountCode(args[1]),
      "getAccountStorage": () => getAccountStorage(args[1], args[2]),
      "getBlock": () => getBlock(args[1]),
      "getTransaction": () => getTransaction(args[1]),
      "getTransactionReceipt": () => getTransactionReceipt(args[1]),
    };

    if (methodMap.containsKey(args[0])) {
      return methodMap[args[0]]();
    }
  }

  static Future<Map<String, dynamic>> status() async {
    var fn = (time) => (time - genesisTime) ~/ interval;
    dynamic block = await getBlock("best");
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

  static dynamic getBlock(dynamic revision) async {
    Response response = await dio.get("$testnet/blocks/$revision");
    return response.data;
  }

  static dynamic getTransaction(String txId) async {
    Response response = await dio.get("$testnet/transactions/$txId");
    return response.data;
  }

  static dynamic getTransactionReceipt(String txId) async {
    Response response = await dio.get("$testnet/transactions/$txId/receipt");
    return response.data;
  }

  static dynamic getAccount(String address) async {
    Response response = await dio.get("$testnet/accounts/$address");
    return response.data;
    // throw BadParameter("'addr' expected address type");
  }

  static dynamic getAccountCode(String address) async {
    Response response = await dio.get("$testnet/accounts/$address/code");
    return response.data;
  }

  static dynamic getAccountStorage(String address, String key) async {
    Response response =
        await dio.get("$testnet/accounts/$address/Storage/$key");
    return response.data;
  }

  static dynamic senTransaction(String raw) async {
    Response response =
        await dio.post("$testnet/transactions", data: {"raw": raw});
    return response.data;
  }
}
