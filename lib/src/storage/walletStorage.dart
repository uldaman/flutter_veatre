import 'dart:convert';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/crypto.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/storage/configStorage.dart';

class WalletStorage {
  static Future<List<WalletEntity>> readAll({Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return List.from(rows.map((row) => WalletEntity.fromJSON(row)));
  }

  static Future<List<String>> wallets({Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return List.from(
        rows.map((row) => '0x${WalletEntity.fromJSON(row).address}'));
  }

  static Future<int> count({Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'network = ?',
      whereArgs: [(network ?? Globals.network) == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return rows.length;
  }

  static Future<bool> hasName(String name, {Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'name = ? and network = ?',
      whereArgs: [
        name,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
      orderBy: 'id desc',
    );
    return rows.length != 0;
  }

  static Future<void> updateName(String address, String name,
      {Network network}) async {
    await Storage.update(
      walletTableName,
      {'name': name},
      where: 'address = ? and network = ? ',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
    );
  }

  static Future<void> updateHasBackup(
    String address,
    bool hasBackup, {
    Network network,
  }) async {
    await Storage.update(
      walletTableName,
      {'hasBackup': hasBackup ? 0 : 1},
      where: 'address = ? and network = ? ',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
    );
  }

  static Future<bool> hasWallet(String address, {Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'address = ? and network = ?',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
      orderBy: 'id desc',
    );
    return rows.length != 0;
  }

  static Future<WalletEntity> read(String address, {Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'address = ? and network = ?',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1
      ],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return WalletEntity.fromJSON(rows.first);
  }

  static Future<void> write(WalletEntity walletEntity,
      {Network network}) async {
    walletEntity.network = network ?? Globals.network;
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'address = ? and network = ?',
      whereArgs: [
        walletEntity.address,
        walletEntity.network == Network.MainNet ? 0 : 1
      ],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return Storage.insert(walletTableName, walletEntity.encoded);
    }
    return Storage.update(
      walletTableName,
      walletEntity.encoded,
      where: 'address = ? and network = ?',
      whereArgs: [
        walletEntity.address,
        walletEntity.network == Network.MainNet ? 0 : 1,
      ],
    );
  }

  static Future<void> setMainWallet(WalletEntity walletEntity,
      {Network network}) async {
    return Storage.inTransaction((transaction) async {
      final batch = transaction.batch();
      network = network ?? Globals.network;
      batch.update(
        walletTableName,
        {
          'isMain': 1,
        },
        where: 'isMain != ? and network = ?',
        whereArgs: [
          1,
          network == Network.MainNet ? 0 : 1,
        ],
      );
      batch.update(
        walletTableName,
        {
          'isMain': 0,
        },
        where: 'address = ? and network = ?',
        whereArgs: [
          walletEntity.address,
          network == Network.MainNet ? 0 : 1,
        ],
      );
      await batch.commit(noResult: true);
    });
  }

  static Future<WalletEntity> getMainWallet({Network network}) async {
    List<Map<String, dynamic>> rows = await Storage.query(
      walletTableName,
      where: 'isMain = ? and network = ?',
      whereArgs: [
        0,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1,
      ],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return WalletEntity.fromJSON(rows.first);
  }

  static Future<WalletEntity> getWalletEntity(String signer,
      {Network network}) async {
    network = network ?? Globals.network;
    if (signer != null) {
      List<WalletEntity> walletEntities =
          await WalletStorage.readAll(network: network);
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity =
        await WalletStorage.getMainWallet(network: network);
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities =
        await WalletStorage.readAll(network: network);
    return walletEntities[0];
  }

  static Future<void> delete(String address, {Network network}) async {
    await Storage.delete(
      walletTableName,
      where: 'address = ? and network = ?',
      whereArgs: [
        address,
        (network ?? Globals.network) == Network.MainNet ? 0 : 1,
      ],
    );
  }

  static Future<void> saveWallet(
    String address,
    String name,
    String mnemonic,
    String password, {
    Network network,
  }) async {
    final mnemonicData = utf8.encode(mnemonic);
    final iv = randomBytes(16);
    final mnemonicCipher = AESCipher.encrypt(
      utf8.encode(password),
      mnemonicData,
      iv,
    );
    final WalletEntity walletEntity = WalletEntity(
      name: name,
      address: address,
      mnemonicCipher: bytesToHex(mnemonicCipher),
      iv: bytesToHex(iv),
      isMain: true,
      hasBackup: false,
      network: network ?? Globals.network,
    );
    await WalletStorage.write(walletEntity);
    await WalletStorage.setMainWallet(walletEntity, network: network);
  }
}
