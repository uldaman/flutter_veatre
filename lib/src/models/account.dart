import 'dart:convert';
import 'dart:typed_data';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/models/crypto.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/configStorage.dart';

class Account {
  final BigInt balance;
  final BigInt energy;
  final bool hasCode;

  Account({this.balance, this.energy, this.hasCode});

  String get formatBalance {
    return formatNum(fixed2Value(balance));
  }

  String get formatEnergy {
    return formatNum(fixed2Value(energy));
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

class WalletEntity {
  String name;
  String address;
  String mnemonicCipher;
  String iv;
  bool isMain;
  bool hasBackup;
  Network network;

  WalletEntity({
    this.name,
    this.address,
    this.mnemonicCipher,
    this.iv,
    this.isMain = false,
    this.hasBackup = false,
    this.network,
  });

  Map<String, dynamic> get encoded {
    return {
      'name': name,
      'address': address,
      'mnemonicCipher': mnemonicCipher,
      'iv': iv,
      'isMain': isMain ? 0 : 1,
      'hasBackup': hasBackup ? 0 : 1,
      'network': network == Network.MainNet ? 0 : 1,
    };
  }

  factory WalletEntity.fromJSON(Map<String, dynamic> parsedJson) {
    return WalletEntity(
      name: parsedJson['name'],
      address: parsedJson['address'],
      mnemonicCipher: parsedJson['mnemonicCipher'],
      iv: parsedJson['iv'],
      hasBackup: parsedJson['hasBackup'] == 0,
      isMain: parsedJson['isMain'] == 0,
      network: parsedJson['network'] == 0 ? Network.MainNet : Network.TestNet,
    );
  }

  Future<Uint8List> decryptPrivateKey(
    Uint8List passcodes,
  ) async {
    Uint8List mnemonicData = AESCipher.decrypt(
      passcodes,
      hexToBytes(mnemonicCipher),
      hexToBytes(iv),
    );
    String mnemonic = utf8.decode(mnemonicData);
    return BipKeyDerivation.decryptedByMnemonic(
      mnemonic,
      defaultDerivationPath,
    );
  }
}
