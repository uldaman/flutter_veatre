import 'dart:typed_data';

import 'package:veatre/src/api/API.dart';
import 'package:web3dart/crypto.dart';

class TransactionAPI {
  static Future<Map<dynamic, dynamic>> send(Uint8List raw) async {
    return API.post("/transactions", {"raw": "0x" + bytesToHex(raw)});
  }
}
