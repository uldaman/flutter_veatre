import 'dart:typed_data';

import 'package:veatre/common/vechain.dart';
import 'package:web3dart/crypto.dart';

class TransactionAPI {
  static Future<Map<dynamic, dynamic>> send(Uint8List raw) async {
    return Vechain.senTransaction("0x" + bytesToHex(raw));
  }
}
