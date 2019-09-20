import 'package:bip_key_derivation/keystore.dart';
import 'package:veatre/src/api/AccountAPI.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/utils/common.dart';

class Account {
  final BigInt balance;
  final BigInt energy;
  final bool hasCode;

  Account({this.balance, this.energy, this.hasCode});

  String get formatBalance {
    return fixed2Value(balance);
  }

  String get formatEnergy {
    return fixed2Value(energy);
  }

  factory Account.fromJSON(Map<String, dynamic> parsedJson) {
    return Account(
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

  static Future<Wallet> from(WalletEntity walletEntity, Network network) async {
    try {
      Account acc =
          await AccountAPI.get(walletEntity.keystore.address, network);
      return Wallet(
        account: acc,
        keystore: walletEntity.keystore,
        name: walletEntity.name,
      );
    } catch (e) {
      return Wallet(
        account: Account(
          balance: BigInt.from(0),
          energy: BigInt.from(0),
          hasCode: false,
        ),
        keystore: walletEntity.keystore,
        name: walletEntity.name,
      );
    }
  }
}
