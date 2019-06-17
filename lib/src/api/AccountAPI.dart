import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/common/net.dart';

class AccountAPI {
  static final net = Net(network: testnet);

  static Future<Account> get(String address) async {
    String addr = address.startsWith('0x') ? address : '0x$address';
    print(addr);
    Map<String, dynamic> json = await net.getAccount(addr);
    print(json);

    return Account.fromJSON(json);
  }

  static Future<List<CallResult>> call(
    List<SigningTxMessage> txMessages, {
    String caller,
    BigInt gasPrice,
    int gas,
    dynamic revision = '',
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
    print(clausesJson);
    List<dynamic> callResults = await net.explain({
      'clauses': clausesJson,
      'caller': addr,
      'gasPrice': gasPrice,
      'gas': gas,
    }, revision: revision);
    print("callResults: $callResults");
    List<CallResult> results = [];
    for (Map<String, dynamic> callResult in callResults) {
      results.add(CallResult.fromJSON(callResult));
    }
    return results;
  }
}
