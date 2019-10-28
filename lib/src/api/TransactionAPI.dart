import 'dart:typed_data';

import 'package:veatre/common/globals.dart';
import 'package:web3dart/crypto.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/configStorage.dart';

class TransactionAPI {
  static Future<Map<String, dynamic>> send(
    Uint8List raw, {
    Network network,
  }) async {
    final net = Config.net(network: network ?? Globals.network);
    Map<String, dynamic> data =
        await net.senTransaction("0x" + bytesToHex(raw));
    return data;
  }

  static Future<List<Transfer>> filterTransfers(
    String address,
    int offset,
    int limit, {
    Network network,
  }) async {
    String addr = address.startsWith('0x') ? address : '0x$address';
    final net = Config.net(network: network ?? Globals.network);
    dynamic data = await net.filterTransferLogs({
      "range": {
        "unit": "block",
        "from": 0,
        "to": 4294967295,
      },
      "options": {
        "offset": offset,
        "limit": limit,
      },
      "criteriaSet": [
        {"sender": addr},
        {"recipient": addr},
      ],
      "order": "desc"
    });
    List<Transfer> transfers = [];
    for (Map<String, dynamic> json in data) {
      transfers.add(Transfer.fromJSON(json));
    }
    return transfers;
  }
}
