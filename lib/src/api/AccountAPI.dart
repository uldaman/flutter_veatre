import 'package:veatre/src/models/Account.dart';
import 'package:veatre/src/api/API.dart';

class AccountAPI {
  static Future<Account> getAccount(String address) async {
    Map<dynamic, dynamic> json = await API.get("/accounts/" + address);
    Account acc = Account.fromJSON(json);
    acc.address = address;
    return acc;
  }
}
