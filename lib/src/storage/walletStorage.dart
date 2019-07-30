import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:veatre/main.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class WalletStorage {
  static final storage = new FlutterSecureStorage();
  static final _mainNetMainWalletKey =
      "c2a06a2a14f08900c9c03d51e896eb77"; //MD5 ("mainNetMainWalletKey") = c2a06a2a14f08900c9c03d51e896eb77
  static final _testNeMainWalletKey =
      "75608f52a2e04dfb14f943d081dd30af"; // MD5 ("testNeMainWalletKey") = 75608f52a2e04dfb14f943d081dd30af
  static final _testNetWalletPrefix = 'TestNetWallet|';
  static final _mainNetWalletPrefix = 'MainNetWallet|';

  static Future<List<WalletEntity>> readAll() async {
    Map<String, String> allKeystores = await storage.readAll();
    bool isMainNet = await NetworkStorage.isMainNet;
    List<WalletEntity> walletEntities = [];
    if (isMainNet) {
      for (var keystoreEntity in allKeystores.entries) {
        String walletKey = keystoreEntity.key;
        if (walletKey.startsWith(_mainNetWalletPrefix)) {
          KeyStore keystore =
              KeyStore.fromJSON(json.decode(keystoreEntity.value));
          walletEntities.add(
            WalletEntity(
              name: walletKey.substring(_mainNetWalletPrefix.length),
              keystore: keystore,
            ),
          );
        }
      }
    } else {
      for (var keystoreEntity in allKeystores.entries) {
        String walletKey = keystoreEntity.key;
        if (walletKey.startsWith(_testNetWalletPrefix)) {
          KeyStore keystore =
              KeyStore.fromJSON(json.decode(keystoreEntity.value));
          walletEntities.add(
            WalletEntity(
              name: walletKey.substring(_testNetWalletPrefix.length),
              keystore: keystore,
            ),
          );
        }
      }
    }
    return walletEntities;
  }

  static Future<List<String>> wallets(Network network) async {
    Map<String, String> allKeystores = await storage.readAll();
    List<String> wallets = [];
    if (network == Network.MainNet) {
      for (var keystoreEntity in allKeystores.entries) {
        String walletKey = keystoreEntity.key;
        if (walletKey.startsWith(_mainNetWalletPrefix)) {
          KeyStore keystore =
              KeyStore.fromJSON(json.decode(keystoreEntity.value));
          wallets.add("0x${keystore.address}");
        }
      }
    } else {
      for (var keystoreEntity in allKeystores.entries) {
        String walletKey = keystoreEntity.key;
        if (walletKey.startsWith(_testNetWalletPrefix)) {
          KeyStore keystore =
              KeyStore.fromJSON(json.decode(keystoreEntity.value));
          wallets.add("0x${keystore.address}");
        }
      }
    }
    return wallets;
  }

  static Future<WalletEntity> read(String name) async {
    bool isMainNet = await NetworkStorage.isMainNet;
    String keystoreString = await storage.read(
      key:
          isMainNet ? _mainNetWalletPrefix + name : _testNetWalletPrefix + name,
    );
    if (keystoreString == null) {
      return null;
    }
    KeyStore keystore = KeyStore.fromJSON(json.decode(keystoreString));
    return WalletEntity(name: name, keystore: keystore);
  }

  static Future<void> write(
      {WalletEntity walletEntity, bool isMainWallet = false}) async {
    if (await NetworkStorage.isMainNet) {
      await storage.write(
        key: _mainNetWalletPrefix + walletEntity.name,
        value: json.encode(walletEntity.keystore.encoded),
      );
      if (isMainWallet) {
        await storage.write(
          key: _mainNetMainWalletKey,
          value: json.encode(walletEntity.encoded),
        );
      }
      mainNetWalletsController.value = await wallets(Network.MainNet);
    } else {
      await storage.write(
        key: _testNetWalletPrefix + walletEntity.name,
        value: json.encode(walletEntity.keystore.encoded),
      );
      if (isMainWallet) {
        await storage.write(
          key: _testNeMainWalletKey,
          value: json.encode(walletEntity.encoded),
        );
      }
      testNetWalletsController.value = await wallets(Network.MainNet);
    }
  }

  static Future<void> setMainWallet(WalletEntity walletEntity) async {
    bool isMainNet = await NetworkStorage.isMainNet;
    await storage.write(
      key: isMainNet ? _mainNetMainWalletKey : _testNeMainWalletKey,
      value: json.encode(walletEntity.encoded),
    );
  }

  static Future<WalletEntity> getMainWallet() async {
    bool isMainNet = await NetworkStorage.isMainNet;
    String mainWalletString = await storage.read(
        key: isMainNet ? _mainNetMainWalletKey : _testNeMainWalletKey);
    if (mainWalletString == null) {
      return null;
    }
    return WalletEntity.fromJSON(json.decode(mainWalletString));
  }

  static Future<void> delete(String name) async {
    bool isMainNet = await NetworkStorage.isMainNet;
    if (isMainNet) {
      await storage.delete(key: _mainNetWalletPrefix + name);
      mainNetWalletsController.value = await wallets(Network.MainNet);
    } else {
      await storage.delete(key: _testNetWalletPrefix + name);
      testNetWalletsController.value = await wallets(Network.TestNet);
    }
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
