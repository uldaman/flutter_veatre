import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:veatre/main.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class WalletStorage {
  static final storage = new FlutterSecureStorage();
  static final mainWalletKey =
      "6026f74a96577f186b25f9a471d79f39"; // md5(MainWallet)

  static Future<List<WalletEntity>> readAll() async {
    Map<String, String> allKeystores = await storage.readAll();
    List<WalletEntity> walletEntities = [];
    for (var keystoreEntity in allKeystores.entries) {
      String walletName = keystoreEntity.key;
      if (walletName != mainWalletKey &&
          walletName != NetworkStorage.networkKey) {
        KeyStore keystore =
            KeyStore.fromJSON(json.decode(keystoreEntity.value));
        walletEntities.add(WalletEntity(name: walletName, keystore: keystore));
      }
    }
    return walletEntities;
  }

  static Future<List<String>> get wallets async {
    Map<String, String> allKeystores = await storage.readAll();
    List<String> wallets = [];
    for (var keystoreEntity in allKeystores.entries) {
      String walletName = keystoreEntity.key;
      if (walletName != mainWalletKey &&
          walletName != NetworkStorage.networkKey) {
        KeyStore keystore =
            KeyStore.fromJSON(json.decode(keystoreEntity.value));
        wallets.add("0x${keystore.address}");
      }
    }
    return wallets;
  }

  static Future<WalletEntity> read(String name) async {
    String keystoreString = await storage.read(key: name);
    if (keystoreString == null) {
      return null;
    }
    KeyStore keystore = KeyStore.fromJSON(json.decode(keystoreString));
    return WalletEntity(name: name, keystore: keystore);
  }

  static Future<void> write(
      {WalletEntity walletEntity, bool isMainWallet = false}) async {
    await storage.write(
      key: walletEntity.name,
      value: json.encode(walletEntity.keystore.encoded),
    );
    if (isMainWallet) {
      await storage.write(
        key: mainWalletKey,
        value: json.encode(walletEntity.encoded),
      );
    }
    walletsController.value = await wallets;
  }

  static Future<void> setMainWallet(WalletEntity walletEntity) async {
    await storage.write(
      key: mainWalletKey,
      value: json.encode(walletEntity.encoded),
    );
  }

  static Future<WalletEntity> getMainWallet() async {
    String mainWalletString = await storage.read(key: mainWalletKey);
    if (mainWalletString == null) {
      return null;
    }
    return WalletEntity.fromJSON(json.decode(mainWalletString));
  }

  static Future<void> delete(String name) async {
    await storage.delete(key: name);
    walletsController.value = await wallets;
  }

  static Future<void> deleteAll() async {
    await storage.deleteAll();
    walletsController.value = await wallets;
  }
}

class WalletEntity {
  String name;
  KeyStore keystore;

  WalletEntity({this.name, this.keystore});

  Map<String, dynamic> get encoded {
    return {
      'name': this.name,
      'keystore': this.keystore.encoded,
    };
  }

  factory WalletEntity.fromJSON(Map<String, dynamic> parsedJson) {
    return WalletEntity(
      name: parsedJson['name'],
      keystore: KeyStore.fromJSON(
        parsedJson['keystore'],
      ),
    );
  }
}
