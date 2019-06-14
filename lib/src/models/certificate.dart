import 'dart:convert';
import 'dart:typed_data';
import 'package:veatre/src/models/Crypto.dart';
import 'package:pointycastle/digests/blake2b.dart';
import "package:pointycastle/ecc/api.dart";
import 'package:web3dart/crypto.dart';

class Certificate {
  String domain;
  Payload payload;
  String purpose;
  String signer;
  int timestamp;

  Uint8List _signature = Uint8List(0);

  Certificate({
    String domain,
    int timestamp,
    String purpose,
    Payload payload,
  }) {
    this.domain = domain ?? '';
    this.timestamp = timestamp ?? 0;
    this.purpose = purpose ?? '';
    this.payload = payload ?? Payload();
  }

  void sign(Uint8List privateKey) {
    Uint8List publicKey = privateKeyBytesToPublic(privateKey);
    Uint8List address = publicKeyToAddress(publicKey);
    signer = '0x' + bytesToHex(address);
    _signature = Crypto.sign(signingHash, privateKey);
  }

  bool verify() {
    if (_signature.length != 65) {
      return false;
    }
    Uint8List rData = Uint8List(32);
    Uint8List sData = Uint8List(32);
    List.copyRange(rData, 0, _signature, 0, 32);
    List.copyRange(sData, 0, _signature, 32, 64);
    BigInt r = BigInt.parse(bytesToHex(rData), radix: 16);
    BigInt s = BigInt.parse(bytesToHex(sData), radix: 16);
    Uint8List publicKey =
        Crypto.sigToPub(_signature.last, ECSignature(r, s), signingHash);
    Uint8List address = publicKeyToAddress(publicKey);
    return '0x' + bytesToHex(address) == signer;
  }

  Uint8List get signingHash {
    Map<String, dynamic> unserializedData = unserialized;
    Blake2bDigest blake2b = Blake2bDigest(digestSize: 32);
    Uint8List data = utf8.encode(json.encode(unserializedData));
    return blake2b.process(data);
  }

  factory Certificate.fromJSON(Map<String, dynamic> parsedJSON) {
    return Certificate(
      domain: parsedJSON['domain'] ?? '',
      timestamp: parsedJSON['timestamp'] ?? 0,
      purpose: parsedJSON['purpose'] ?? '',
      payload: parsedJSON['payload'] ?? Payload(),
    );
  }

  Map<String, dynamic> get encoded {
    return {
      'domain': domain,
      'payload': payload.encoded,
      'purpose': purpose,
      'signer': signer,
      'timestamp': timestamp.toInt(),
      '_signature': bytesToHex(_signature),
    };
  }

  Map<String, dynamic> get unserialized {
    return {
      'domain': domain,
      'payload': payload.encoded,
      'purpose': purpose,
      'signer': signer,
      'timestamp': timestamp,
    };
  }
}

class Payload {
  String content;
  String type;

  Payload({
    String content = '',
    String type = '',
  }) {
    this.content = content;
    this.type = type;
  }

  Map<String, String> get encoded {
    return {
      'content': content,
      'type': type,
    };
  }
}
