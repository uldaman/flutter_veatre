import 'package:veatre/src/models/keyStore.dart';

class Account {
  final BigInt balance;
  final BigInt energy;
  final bool hasCode;

  static final unit = BigInt.from(1e18);

  Account({this.balance, this.energy, this.hasCode});

  static String fixed2Value(BigInt value) {
    double v = (value / unit).toDouble();
    String fixed2 = v.toStringAsFixed(2);
    if (fixed2.split('.')[1].endsWith('0')) {
      String fixed1 = v.toStringAsFixed(1);
      if (fixed1.split('.')[1].endsWith('0')) {
        return v.toStringAsFixed(0);
      }
      return fixed1;
    }
    return fixed2;
  }

  String formatBalance() {
    return fixed2Value(balance);
  }

  String formatEnergy() {
    return fixed2Value(energy);
  }

  factory Account.fromJSON(Map<String, dynamic> parsedJson) {
    return Account(
      // address: parsedJson['address'] == null ? '' : parsedJson['address'],
      balance: parsedJson['balance'] == null
          ? BigInt.from(0)
          : BigInt.parse(parsedJson['balance']),
      energy: parsedJson['energy'] == null
          ? BigInt.from(0)
          : BigInt.parse(parsedJson['energy']),
      hasCode: parsedJson['hasCode'],
    );
  }
}

class Wallet {
  Account account;
  KeyStore keystore;
  String name;

  Wallet({this.account, this.keystore, this.name});
}
