import 'package:veatre/common/globals.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/configStorage.dart';

class AccountAPI {
  static Future<Account> get(String address, {Network network}) async {
    final net = Config.net(network: network ?? Globals.network);
    String addr = address.startsWith('0x') ? address : '0x$address';
    Map<String, dynamic> json = await net.getAccount(addr);
    return Account.fromJSON(json);
  }

  static Future<List<CallResult>> call(
    List<SigningTxMessage> txMessages, {
    String caller = '0x0000000000000000000000000000000000000000',
    BigInt gasPrice,
    int gas,
    dynamic revision = '',
    Network network,
  }) async {
    String addr = caller.startsWith('0x') ? caller : '0x$caller';
    List<Map<String, dynamic>> clausesJson = [];
    for (SigningTxMessage txMsg in txMessages) {
      clausesJson.add({
        'to': txMsg.to,
        'value': txMsg.value,
        'data': txMsg.data,
      });
    }
    final net = Config.net(network: network ?? Globals.network);
    List<dynamic> callResults = await net.explain({
      'clauses': clausesJson,
      'caller': addr,
      'gasPrice': gasPrice,
      'gas': gas,
    }, revision: revision);
    List<CallResult> results = [];
    for (Map<String, dynamic> callResult in callResults) {
      results.add(CallResult.fromJSON(callResult));
    }
    return results;
  }
}
