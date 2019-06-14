import "package:dio/dio.dart";

final testnet = "https://sync-testnet.vechain.org";
final mainnet = "https://sync-mainnet.vechain.org";

final genesisTime = 1530014400;
final interval = 10;

class BadParameter implements Exception {
  final String msg;

  const BadParameter(this.msg);

  String toString() {
    return "BadParameter: ${this.msg}";
  }
}

class Net {
  static final dio = Dio();
  String network = testnet;
  Net({this.network});

  Future<Map<String, dynamic>> status() async {
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

  dynamic getBlock(dynamic revision) async {
    Response response = await dio.get("$network/blocks/$revision");
    return response.data;
  }

  dynamic getTransaction(String txId) async {
    Response response = await dio.get("$network/transactions/$txId");
    return response.data;
  }

  dynamic getReceipt(String txId) async {
    Response response = await dio.get("$network/transactions/$txId/receipt");
    return response.data;
  }

  dynamic getAccount(String address) async {
    Response response = await dio.get("$network/accounts/$address");
    return response.data;
    // throw BadParameter("'addr' expected address type");
  }

  dynamic getCode(String address) async {
    Response response = await dio.get("$network/accounts/$address/code");
    return response.data;
  }

  dynamic getStorage(String address, String key) async {
    Response response =
        await dio.get("$network/accounts/$address/Storage/$key");
    return response.data;
  }

  dynamic filterTransferLogs(Map<String, dynamic> data) async {
    Response response = await dio.post("$network/transfers", data: data);
    return response.data;
  }

  dynamic filterEventLogs(Map<String, dynamic> data) async {
    Response response = await dio.post("$network/events", data: data);
    return response.data;
  }

  dynamic explain(Map<String, dynamic> callData, dynamic revision) async {
    Response response = await dio.post("$network/accounts/*?revision=$revision",
        data: callData);
    return response.data;
  }

  dynamic senTransaction(String raw) async {
    Response response =
        await dio.post("$network/transactions", data: {"raw": raw});
    return response.data;
  }
}
