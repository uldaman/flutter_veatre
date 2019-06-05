import 'package:veatre/src/models/account.dart';
import 'package:veatre/common/vechain.dart';

class AccountAPI {
  static Future<Account> get(String address) async {
    String addr = address.startsWith('0x') ? address : '0x$address';
    Map<dynamic, dynamic> json = await Vechain.getAccount(addr);
    print(json);
    Account acc = Account.fromJSON(json);
    return acc;
  }
}
