import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/utils/common.dart';

class Account {
  final BigInt balance;
  final BigInt energy;
  final bool hasCode;

  Account({this.balance, this.energy, this.hasCode});

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
