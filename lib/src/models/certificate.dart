import 'dart:convert';
import 'dart:typed_data';
import 'package:veatre/src/models/Crypto.dart';
import 'package:pointycastle/digests/blake2b.dart';
import "package:pointycastle/ecc/api.dart";
import 'package:web3dart/crypto.dart';

class Certificate {
  String domain;
  SigningCertMessage certMessage;
  int timestamp;

  String _signer;
  Uint8List _signature = Uint8List(0);

  Certificate({
    String domain,
    int timestamp,
    SigningCertMessage certMessage,
  }) {
    this.domain = domain ?? '';
    this.timestamp = timestamp ?? 0;
    this.certMessage = certMessage;
  }

  void sign(Uint8List privateKey) {
    Uint8List publicKey = privateKeyBytesToPublic(privateKey);
    Uint8List address = publicKeyToAddress(publicKey);
    _signer = '0x' + bytesToHex(address);
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
    return '0x' + bytesToHex(address) == _signer;
  }

  Uint8List get signingHash {
    Map<String, dynamic> unserializedData = unserialized;
    Blake2bDigest blake2b = Blake2bDigest(digestSize: 32);
    Uint8List data = utf8.encode(json.encode(unserializedData));
    return blake2b.process(data);
  }

  SigningCertResponse get encoded {
    return SigningCertResponse(
      annex: Annex(
        signer: _signer,
        timestamp: timestamp,
        domain: domain,
      ),
      signature: '0x' + bytesToHex(_signature),
    );
  }

  Map<String, dynamic> get unserialized {
    return {
      'domain': domain,
      'payload': certMessage.payload.encoded,
      'purpose': certMessage.purpose,
      'signer': _signer,
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

  factory Payload.fromJSON(Map<String, dynamic> parsedJSON) {
    return Payload(
      content: parsedJSON['content'],
      type: parsedJSON['type'],
    );
  }
}

class SigningCertMessage {
  String purpose;
  Payload payload;

  SigningCertMessage({
    this.purpose,
    this.payload,
  });

  factory SigningCertMessage.fromJSON(Map<String, dynamic> parsedJSON) {
    return SigningCertMessage(
      purpose: parsedJSON['purpose'] ?? '',
      payload: Payload.fromJSON(parsedJSON['payload']) ?? '',
    );
  }
}

class SigningCertOptions {
  String signer;
  String link;

  SigningCertOptions({
    this.signer,
    this.link,
  });

  factory SigningCertOptions.fromJSON(Map<String, dynamic> parsedJSON) {
    return SigningCertOptions(
      signer: parsedJSON['signer'],
      link: parsedJSON['link'],
    );
  }
}

class SigningCertResponse {
  Annex annex;
  String signature;

  SigningCertResponse({
    this.annex,
    this.signature,
  });

  Map<String, dynamic> get encoded {
    return {
      'annex': annex.encoded,
      'signature': signature,
    };
  }
}

class Annex {
  String domain;
  int timestamp;
  String signer;

  Annex({
    this.domain,
    this.timestamp,
    this.signer,
  });

  Map<String, dynamic> get encoded {
    return {
      'domain': domain,
      'timestamp': timestamp,
      'signer': signer,
    };
  }
}
