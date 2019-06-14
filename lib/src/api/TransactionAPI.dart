import 'dart:typed_data';

import 'package:veatre/common/net.dart';
import 'package:web3dart/crypto.dart';

class TransactionAPI {
  static final net = Net();

  static Future<Map<String, dynamic>> send(Uint8List raw) async {
    Map<String, dynamic> data =
        await net.senTransaction("0x" + bytesToHex(raw));
    return data;
  }
}
