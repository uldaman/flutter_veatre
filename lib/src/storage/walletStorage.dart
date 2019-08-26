import 'dart:convert';
import 'package:bip_key_derivation/keystore.dart';
import 'package:veatre/src/storage/database.dart';
import 'package:veatre/src/storage/networkStorage.dart';

class WalletStorage {
  static Future<List<WalletEntity>> readAll(Network network) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      walletTableName,
      where: 'network = ?',
      whereArgs: [network == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    return List.from(rows.map((row) => WalletEntity.fromJSON(row)));
  }

  static Future<List<String>> wallets(Network network) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      walletTableName,
      where: 'network = ?',
      whereArgs: [network == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    print('wallets $rows');
    return List.from(
        rows.map((row) => '0x${WalletEntity.fromJSON(row).keystore.address}'));
  }

  static Future<WalletEntity> read(String name, Network network) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      walletTableName,
      where: 'name = ? and network = ?',
      whereArgs: [name, network == Network.MainNet ? 0 : 1],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return WalletEntity.fromJSON(rows.first);
  }

  static Future<void> write({WalletEntity walletEntity}) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      walletTableName,
      where: 'name = ? and network = ?',
      whereArgs: [
        walletEntity.name,
        walletEntity.network == Network.MainNet ? 0 : 1
      ],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return db.insert(walletTableName, walletEntity.encoded);
    }
    return db.update(
      walletTableName,
      walletEntity.encoded,
      where: 'name = ? and network = ?',
      whereArgs: [
        walletEntity.name,
        walletEntity.network == Network.MainNet ? 0 : 1,
      ],
    );
  }

  static Future<void> setMainWallet(
      WalletEntity walletEntity, Network network) async {
    final db = await database;
    await db.update(
      walletTableName,
      {'isMain': 1},
      where: 'isMain != ? and network = ?',
      whereArgs: [
        1,
        network == Network.MainNet ? 0 : 1,
      ],
    );
    walletEntity.isMain = true;
    return db.update(
      walletTableName,
      walletEntity.encoded,
      where: 'name = ?',
      whereArgs: [
        walletEntity.name,
      ],
    );
  }

  static Future<WalletEntity> getMainWallet(Network network) async {
    final db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      walletTableName,
      where: 'isMain = ? and network = ?',
      whereArgs: [
        0,
        network == Network.MainNet ? 0 : 1,
      ],
      orderBy: 'id desc',
    );
    if (rows.length == 0) {
      return null;
    }
    return WalletEntity.fromJSON(rows.first);
  }

  static Future<void> delete(String name, Network network) async {
    final db = await database;
    await db.delete(
      walletTableName,
      where: 'name = ? and network = ?',
      whereArgs: [
        name,
        network == Network.MainNet ? 0 : 1,
      ],
    );
  }
}

class WalletEntity {
  String name;
  KeyStore keystore;
  bool isMain;
  Network network;

  WalletEntity({
    this.name,
    this.keystore,
    this.isMain = false,
    this.network,
  });

  Map<String, dynamic> get encoded {
    return {
      'name': name,
      'keystore': json.encode(keystore.encoded),
      'isMain': isMain ? 0 : 1,
      'network': network == Network.MainNet ? 0 : 1,
    };
  }

  factory WalletEntity.fromJSON(Map<String, dynamic> parsedJson) {
    return WalletEntity(
      name: parsedJson['name'],
      keystore: KeyStore.fromJSON(
        json.decode(parsedJson['keystore']),
      ),
      isMain: parsedJson['isMain'] == 0 ? true : false,
      network: parsedJson['network'] == 0 ? Network.MainNet : Network.TestNet,
    );
  }
}
