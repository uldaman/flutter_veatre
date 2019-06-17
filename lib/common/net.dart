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
  final String network;
  Net(this.network);

  dynamic getBlock(dynamic revision) async {
    if (revision == null) {
      revision = "best";
    }
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

  dynamic getAccount(String address, {dynamic revision = "best"}) async {
    Response response = await dio.get("$network/accounts/$address",
        queryParameters: {"revision": revision ?? "best"});
    return response.data;
  }

  dynamic getCode(String address, {dynamic revision = "best"}) async {
    Response response = await dio.get("$network/accounts/$address/code",
        queryParameters: {"revision": revision ?? "best"});
    return response.data;
  }

  dynamic getStorage(String address, String key,
      {dynamic revision = "best"}) async {
    Response response = await dio.get("$network/accounts/$address/Storage/$key",
        queryParameters: {"revision": revision ?? "best"});
    return response.data;
  }

  dynamic filterTransferLogs(Map<String, dynamic> data) async {
    Response response = await dio.post("$network/logs/transfer", data: data);
    return response.data;
  }

  dynamic filterEventLogs(Map<String, dynamic> data) async {
    Response response = await dio.post("$network/logs/event", data: data);
    return response.data;
  }

  dynamic explain(Map<String, dynamic> callData,
      {dynamic revision = "best"}) async {
    Response response = await dio.post("$network/accounts/*",
        data: callData, queryParameters: {"revision": revision ?? "best"});
    return response.data;
  }

  dynamic senTransaction(String raw) async {
    Response response =
        await dio.post("$network/transactions", data: {"raw": raw});
    return response.data;
  }
}
