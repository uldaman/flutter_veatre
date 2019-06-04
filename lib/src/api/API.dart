import 'package:http/http.dart' as http;
import 'dart:convert';

class API {
  // static final host = "sync-mainnet.vechain.org";
  static final host = "sync-testnet.vechain.org";

  // static final host = "localhost:8669";
  static final httpClient = new http.Client();

  static String remoteAddr() {
    return "https://" + host;
  }

  static Future<Map<String, dynamic>> post(
      String url, Map<dynamic, dynamic> body) async {
    try {
      var res =
          await httpClient.post(remoteAddr() + url, body: json.encode(body));
      Map<String, dynamic> data = json.decode(res.body);
      return data;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static get(String url) async {
    try {
      var res = await httpClient.get(remoteAddr() + url);
      return json.decode(res.body);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
