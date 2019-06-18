import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'package:uuid/uuid.dart';
import 'package:web3dart/crypto.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/bip39/mnemonic.dart';
import 'package:veatre/src/bip39/hdkey.dart';

import "package:pointycastle/key_derivators/scrypt.dart";
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/impl.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/stream/ctr.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/digests/sha3.dart';

class KeyStore {
  String id;

  /// Key's address
  String address;

  /// Key header with encrypted private key and crypto parameters.
  KeystoreKeyHeader crypto;

  /// Key version, must be 3.
  final version = 3;

  KeyStore({String id, String address, KeystoreKeyHeader crypto, int version}) {
    if (version != 3) {
      throw 'unsupported version';
    }
    this.id = id;
    this.address = address;
    this.crypto = crypto;
  }

  factory KeyStore.fromJSON(Map<String, dynamic> parsedJson) {
    return KeyStore(
      id: parsedJson['id'],
      address: parsedJson['address'],
      crypto: KeystoreKeyHeader.fromJSON(parsedJson['crypto']),
      version: parsedJson['version'],
    );
  }

  static Future<KeyStore> encrypt(String privateKey, String passphrase,
      [Map<String, dynamic> options]) async {
    String salt = randomHex(64);
    List<int> iv = randomBytes(16);
    String kdf = 'scrypt';
    ScryptParams scryptParams = ScryptParams(1024, 8, 1, 32, hexToBytes(salt));
    ScryptKeyDerivator scryptKeyDerivator =
        ScryptKeyDerivator(params: scryptParams);

    Uint8List encodedPassword = utf8.encode(passphrase);
    Uint8List derivedKey = scryptKeyDerivator.deriveKey(encodedPassword);
    Uint8List ciphertextBytes =
        _encryptPrivateKey(scryptKeyDerivator, encodedPassword, iv, privateKey);
    Uint8List macBuffer = Uint8List(16 + 32);
    List.copyRange(macBuffer, 0, derivedKey, 16, 32);
    List.copyRange(macBuffer, 16, ciphertextBytes);
    String mac = bytesToHex(SHA3Digest(256).process(macBuffer));
    Uint8List publicKey = privateKeyBytesToPublic(hexToBytes(privateKey));
    Uint8List address = publicKeyToAddress(publicKey);

    KeystoreKeyHeader keystoreKeyHeader = KeystoreKeyHeader(
      cipherText: bytesToHex(ciphertextBytes),
      cipher: 'aes-128-ctr',
      cipherParams: CipherParams(iv: bytesToHex(iv)),
      kdf: kdf,
      kdfParams: scryptParams,
      mac: mac,
    );
    return KeyStore(
      id: new Uuid().v4(),
      address: bytesToHex(address),
      crypto: keystoreKeyHeader,
      version: 3,
    );
  }

  static Uint8List decrypt({KeyStore keyS, String passphrase}) {
    List<int> ciphertext = hexToBytes(keyS.crypto.cipherText);
    ScryptParams kdfparams = keyS.crypto.kdfParams;
    Uint8List iv = hexToBytes(keyS.crypto.cipherParams.iv);
    ScryptKeyDerivator scryptKeyDerivator =
        ScryptKeyDerivator(params: kdfparams);

    List<int> encodedPassword = utf8.encode(passphrase);
    List<int> derivedKey = scryptKeyDerivator.deriveKey(encodedPassword);
    Uint8List macBuffer = Uint8List(16 + 32);
    List.copyRange(macBuffer, 0, derivedKey, 16, 32);
    List.copyRange(macBuffer, 16, ciphertext);

    String mac = bytesToHex(SHA3Digest(256).process(macBuffer));
    String macString = keyS.crypto.mac;

    Function eq = const ListEquality().equals;
    if (!eq(mac.toUpperCase().codeUnits, macString.toUpperCase().codeUnits)) {
      throw 'Decryption Failed';
    }
    var aesKey = derivedKey.sublist(0, 16);
    var encryptedPrivateKey = hexToBytes(keyS.crypto.cipherText);
    var aes = _initCipher(false, aesKey, iv);
    return aes.process(encryptedPrivateKey);
  }

  Map<String, dynamic> get encoded {
    return {
      'id': this.id,
      'address': this.address,
      'crypto': this.crypto.encoded,
      'version': this.version,
    };
  }
}

class KeystoreKeyHeader {
  String cipherText;

  /// Cipher algorithm.
  final cipher = "aes-128-ctr";

  /// Cipher parameters.
  CipherParams cipherParams;

  /// Key derivation function, must be scrypt.
  final kdf = "scrypt";

  /// Key derivation function parameters.
  ScryptParams kdfParams;

  /// Message authentication code.
  String mac;

  KeystoreKeyHeader({
    String cipherText,
    String cipher,
    CipherParams cipherParams,
    String kdf,
    ScryptParameters kdfParams,
    String mac,
  }) {
    if (cipherText.length != 64) {
      throw 'invalid cipherText';
    }
    if (cipher != 'aes-128-ctr') {
      throw 'unsupported cipher';
    }
    if (kdf != 'scrypt') {
      throw 'unsupported kdf';
    }
    if (mac.length != 64) {
      throw 'invalid mac';
    }
    this.cipherText = cipherText;
    this.cipherParams = cipherParams;
    this.kdfParams = kdfParams;
    this.mac = mac;
  }

  factory KeystoreKeyHeader.fromJSON(Map<String, dynamic> parsedJson) {
    return KeystoreKeyHeader(
      cipherText: parsedJson["ciphertext"],
      cipher: parsedJson["cipher"],
      cipherParams: CipherParams.fromJson(parsedJson["cipherparams"]),
      kdf: parsedJson["kdf"],
      kdfParams: ScryptParams.fromJSON(parsedJson["kdfparams"]),
      mac: parsedJson["mac"],
    );
  }

  Map<String, dynamic> get encoded {
    var map = {
      'ciphertext': this.cipherText,
      'cipher': this.cipher,
      'cipherparams': this.cipherParams.encoded,
      'kdf': this.kdf,
      'kdfparams': this.kdfParams.encoded,
      'mac': this.mac,
    };
    return map;
  }
}

class CipherParams {
  String iv;
  CipherParams({String iv}) {
    if (iv.length != 32) {
      throw 'invalid iv';
    }
    this.iv = iv;
  }

  factory CipherParams.fromJson(Map<String, dynamic> parsedJson) {
    return CipherParams(iv: parsedJson["iv"]);
  }

  Map<String, String> get encoded {
    return {'iv': this.iv};
  }
}

class ScryptParams extends ScryptParameters {
  final int N;
  final int r;
  final int p;
  final int desiredKeyLength;
  final Uint8List salt;

  ScryptParams(this.N, this.r, this.p, this.desiredKeyLength, this.salt)
      : super(N, r, p, desiredKeyLength, salt);

  Map<String, dynamic> get encoded {
    return {
      "n": this.N,
      "r": this.r,
      "p": this.p,
      "dklen": this.desiredKeyLength,
      "salt": bytesToHex(this.salt),
    };
  }

  factory ScryptParams.fromJSON(Map<String, dynamic> parsedJson) {
    return ScryptParams(
      parsedJson['n'],
      parsedJson['r'],
      parsedJson['p'],
      parsedJson['dklen'],
      hexToBytes(parsedJson['salt']),
    );
  }
}

class ScryptKeyDerivator {
  ScryptParams params;

  ScryptKeyDerivator({this.params});

  Uint8List deriveKey(List<int> password) {
    Scrypt scrypt = Scrypt();
    scrypt.init(this.params);
    return scrypt.process(password);
  }
}

CTRStreamCipher _initCipher(bool forEncryption, List<int> key, List<int> iv) {
  return new CTRStreamCipher(new AESFastEngine())
    ..init(false, new ParametersWithIV(new KeyParameter(key), iv));
}

List<int> _encryptPrivateKey(ScryptKeyDerivator _derivator, Uint8List _password,
    Uint8List _iv, String privateKey) {
  var derived = _derivator.deriveKey(_password);
  var aesKey = derived.sublist(0, 16);
  var aes = _initCipher(true, aesKey, _iv);
  return aes.process(hexToBytes(privateKey));
}

class Decriptions {
  KeyStore keystore;
  String password;

  Decriptions({KeyStore keystore, String password}) {
    this.keystore = keystore;
    this.password = password;
  }
}

Uint8List decrypt(Decriptions decriptions) {
  return KeyStore.decrypt(
    keyS: decriptions.keystore,
    passphrase: decriptions.password,
  );
}

class MnemonicDecriptions {
  String mnemonic;
  String password;

  MnemonicDecriptions({String mnemonic, String password}) {
    this.mnemonic = mnemonic;
    this.password = password;
  }
}

Future<KeyStore> decryptMnemonic(
    MnemonicDecriptions mnemonicDecriptions) async {
  Uint8List seed =
      Mnemonic.generateMasterSeed(mnemonicDecriptions.mnemonic, "");
  Uint8List rootSeed = getRootSeed(seed);
  Uint8List privateKey = getPrivateKey(rootSeed, defaultKeyPathNodes());
  KeyStore keystore = await KeyStore.encrypt(
      bytesToHex(privateKey), mnemonicDecriptions.password);

  return keystore;
}
