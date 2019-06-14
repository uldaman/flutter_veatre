import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/common/net.dart';

class AccountAPI {
  static final net = Net();

  static Future<Account> get(String address) async {
    String addr = address.startsWith('0x') ? address : '0x$address';
    Map<String, dynamic> json = await net.getAccount(addr);
    return Account.fromJSON(json);
  }

  static Future<List<CallResult>> call(
    List<RawClause> clauses, {
    String caller,
    BigInt gasPrice,
    int gas,
    dynamic revision = '',
  }) async {
    String addr = caller.startsWith('0x') ? caller : '0x$caller';
    List<Map<String, dynamic>> clausesJson = [];
    for (RawClause clause in clauses) {
      print(BigInt.parse(clause.value) ~/ BigInt.from(1e18));
      clausesJson.add({
        'to': clause.to,
        'value': clause.value,
        'data': clause.data,
      });
    }
    List<dynamic> callResults = await net.explain({
      'clauses': clausesJson,
      'caller': addr,
      'gasPrice': gasPrice,
      'gas': gas,
    }, revision);
    print("callResults: $callResults");
    List<CallResult> results = [];
    for (Map<String, dynamic> callResult in callResults) {
      results.add(CallResult.fromJSON(callResult));
    }
    return results;
  }
}
