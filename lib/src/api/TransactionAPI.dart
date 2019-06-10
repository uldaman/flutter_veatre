import 'dart:typed_data';

import 'package:veatre/common/vechain.dart';
import 'package:web3dart/crypto.dart';

class TransactionAPI {
  static Future<Map<String, dynamic>> send(Uint8List raw) async {
    Map<String, dynamic> data =
        await Vechain.senTransaction("0x" + bytesToHex(raw));
    return data;
  }
}
