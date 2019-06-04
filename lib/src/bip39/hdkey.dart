import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:veatre/src/bip39/mnemonic.dart';
import 'package:veatre/src/bip39/utils.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:web3dart/crypto.dart';

List<Uint8List> ckdPrivHardened(Uint8List extendedPrivateKey, int index) {
  var curveParamN = new ECCurve_secp256k1().n;

  Uint8List chainCodeParent = new Uint8List(32);
  Uint8List privateKeyParent = new Uint8List(32);
  List.copyRange(privateKeyParent, 0, extendedPrivateKey, 0, 32);
  List.copyRange(chainCodeParent, 0, extendedPrivateKey, 32, 64);

  int hardenedIndex =
      pow(2, 31) + index; // For hardened keys we add 2^31 to the index

  var indexByteArray = intToByteArray(hardenedIndex);

  final padding = new Uint8List(1);

  var data = (padding + privateKeyParent + indexByteArray);

  var dataByteArray = new Uint8List.fromList(data);
//
//  print("Extended PrivKey Input: ${bytesToHex(extendedPrivateKey)}");
//
//  print("Index Byte Array: ${bytesToHex(indexByteArray)}");
//
//  print("PrivateKey Parent: ${bytesToHex(privateKeyParent)}");
//
//  print("DataBuffer Hex: ${bytesToHex(dataByteArray)}");
//
//  print("Data Buffer size: ${dataByteArray.length}");

  Uint8List hmacOutput = hmacSha512(dataByteArray, chainCodeParent);

  Uint8List childChainCode = new Uint8List(32);
  Uint8List childPrivateKey = new Uint8List(32);

  Uint8List leftHandHash = new Uint8List(32);

  List.copyRange(leftHandHash, 0, hmacOutput, 0, 32);
  List.copyRange(childChainCode, 0, hmacOutput, 32, 64);

  // https://bitcoin.org/en/developer-guide#hierarchical-deterministic-key-creation
  BigInt privateKeyBigInt =
      (BigInt.parse(bytesToHex(privateKeyParent), radix: 16) +
              BigInt.parse(bytesToHex(leftHandHash), radix: 16)) %
          curveParamN;

//  print("Addition: ${ bytesToHex(leftHandHash) } + ${ bytesToHex(privateKeyParent)}");

  childPrivateKey = intToBytes(privateKeyBigInt);

  List<Uint8List> chainCodeKeyPair = new List<Uint8List>(2);

  chainCodeKeyPair[0] = childPrivateKey;
  chainCodeKeyPair[1] = childChainCode;

  return chainCodeKeyPair; // Hold both the child private key and the child chain code
}

List<Uint8List> ckdPrivNonHardened(Uint8List extendedPrivateKey, int index) {
  var curveParamN = new ECCurve_secp256k1().n;

  Uint8List chainCodeParent = new Uint8List(32);
  Uint8List privateKeyParent = new Uint8List(32);
  List.copyRange(privateKeyParent, 0, extendedPrivateKey, 0, 32);
  List.copyRange(chainCodeParent, 0, extendedPrivateKey, 32, 64);

  int hardenedIndex = index;

  var indexByteArray = intToByteArray(hardenedIndex);
  String publicKeyParentHex =
      "04" + bytesToHex(privateKeyBytesToPublic(privateKeyParent));
  var pubKCompressed = getCompressedPubKey(publicKeyParentHex);

  var data =
      (intToBytes(BigInt.parse(pubKCompressed, radix: 16)) + indexByteArray);

  var dataByteArray = new Uint8List.fromList(data);

  Uint8List hmacOutput = hmacSha512(dataByteArray, chainCodeParent);

  Uint8List childChainCode = new Uint8List(32);
  Uint8List childPrivateKey = new Uint8List(32);

  Uint8List leftHandHash = new Uint8List(32);

  List.copyRange(leftHandHash, 0, hmacOutput, 0, 32);
  List.copyRange(childChainCode, 0, hmacOutput, 32, 64);

  // https://bitcoin.org/en/developer-guide#hierarchical-deterministic-key-creation
  BigInt privateKeyBigInt =
      (BigInt.parse(bytesToHex(privateKeyParent), radix: 16) +
              BigInt.parse(bytesToHex(leftHandHash), radix: 16)) %
          curveParamN;

  childPrivateKey = intToBytes(privateKeyBigInt);

  List<Uint8List> chainCodeKeyPair = new List<Uint8List>(2);

  chainCodeKeyPair[0] = childPrivateKey;
  chainCodeKeyPair[1] = childChainCode;

  return chainCodeKeyPair; // Hold both the child private key and the child chain code
}

Uint8List getMasterPrivateKey(Uint8List masterSeed) {
  Uint8List rootSeed = getRootSeed(masterSeed);

  var privateKey = new Uint8List(32);

  /// The first 256 bits are saved as Master Private Key
  List.copyRange(privateKey, 0, rootSeed, 0, 32);
  return privateKey;
}

Uint8List getMasterChainCode(Uint8List masterSeed) {
  Uint8List rootSeed = getRootSeed(masterSeed);

  var chainCode = new Uint8List(32);
  List.copyRange(chainCode, 0, rootSeed, 32, 64);

  /// The last 256 bits are saved as Master Chain code
  return chainCode;
}

Uint8List getRootSeed(Uint8List masterSeed) {
  var passphrase = "Bitcoin seed";
  var passphraseByteArray = utf8.encode(passphrase);

  var hmac = new HMac(new SHA512Digest(), 128);

  var rootSeed = new Uint8List(hmac.macSize);

  hmac.init(new KeyParameter(passphraseByteArray));

  hmac.update(masterSeed, 0, masterSeed.length);

  hmac.doFinal(rootSeed, 0);
  return rootSeed;
}

String generateMasterSeedHex(String mnemonic, String passphrase) {
  var seed = Mnemonic.generateMasterSeed(mnemonic, passphrase);
  return bytesToHex(seed);
}

List<Uint8List> ckdPub(Uint8List kpar, Uint8List cpar, int index) {
//print("🎌🎌 [${extendedPrivateKey.length}] Input Extended Key: ${bytesToHex(extendedPrivateKey)}");

  var indexByteArray = intToByteArray(index);

  var data = (kpar + indexByteArray);

  var dataByteArray = new Uint8List.fromList(data);

  Uint8List hmacOutput = hmacSha512(dataByteArray, cpar);

//  print("CDKPub: data => ${bytesToHex(data)} hmac data param");
//  print("CDKPub: Cpar => ${bytesToHex(Cpar)}");
//  print("CDKPub: Kpar => ${bytesToHex(Kpar)}");

  Uint8List ci = new Uint8List(32);
  Uint8List ki = new Uint8List(32);

  Uint8List leftHandHash = new Uint8List(32);

  List.copyRange(leftHandHash, 0, hmacOutput, 0, 32);
  List.copyRange(ci, 0, hmacOutput, 32, 64);

  var kiBigInt =
      bytesToInt(privateKeyBytesToPublic(leftHandHash)) + bytesToInt(kpar);

  ki = intToBytes(kiBigInt);

  List<Uint8List> chainCodeKeyPair = new List<Uint8List>(2);

  chainCodeKeyPair[0] = ki;
  chainCodeKeyPair[1] = ci;

  print("Ci : ${bytesToHex(ci)}");
  print("Ki : ${bytesToHex(ki)}");

  return chainCodeKeyPair; // Hold both the child private key and the child chain code
}

class KeyPathNode {
  int index;
  bool isHardened;

  KeyPathNode(this.index, this.isHardened);
}

Uint8List getPrivateKey(
    Uint8List masterExtendedKey, List<KeyPathNode> pathNodes) {
  List<int> extenedKey = List.from(masterExtendedKey);
  List<Uint8List> keypair = [];
  for (KeyPathNode pathNode in pathNodes) {
    if (pathNode.isHardened) {
      extenedKey =
          ckdPrivHardened(Uint8List.fromList(extenedKey), pathNode.index)
              .expand((i) => i)
              .toList();
    } else {
      keypair = ckdPrivNonHardened(
          new Uint8List.fromList(extenedKey), pathNode.index);
      extenedKey = keypair.expand((i) => i).toList();
    }
  }
  if (keypair.length == 0) {
    throw "invalid node path";
  }
  return keypair[0];
}

String exportExtendedPrivKey(
    {String network,
    String depth,
    String parenFingerPrint,
    String keyIndex,
    String chainCode,
    String key}) {
  return "";
}
