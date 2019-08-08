import "package:dio/dio.dart";
import 'package:veatre/src/models/block.dart';

class Net {
  static final dio = Dio();
  final String network;
  Net(this.network);

  Future<Map<String, dynamic>> getBlock({dynamic revision = "best"}) async {
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
    Response response = await dio.get("$network/accounts/$address/storage/$key",
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

  dynamic http(String method, String path, Map<String, dynamic> params) async {
    if (method == 'GET') {
      Response response = await dio.get(
        path,
        queryParameters: params['query'],
        options: Options(headers: params['headers']),
      );
      return response.data;
    } else if (method == 'POST') {
      Response response = await dio.post(
        path,
        data: params['body'],
        queryParameters: params['query'],
        options: Options(headers: params['headers']),
      );
      return response.data;
    }
    throw 'method not implemented';
  }

  static Future<BlockHead> head(Net net) async {
    return BlockHead.fromJSON(await net.getBlock());
  }
}
