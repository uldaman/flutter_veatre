import 'dart:typed_data';

import 'package:collection/collection.dart';
import "package:pointycastle/api.dart";
import "package:pointycastle/impl.dart";
import "package:pointycastle/stream/ctr.dart";
import "package:pointycastle/block/aes_fast.dart";
import 'package:pointycastle/digests/sha256.dart';
import "package:pointycastle/ecc/api.dart";
import "package:pointycastle/ecc/curves/secp256k1.dart";
import 'package:pointycastle/signers/ecdsa_signer.dart';
import "package:pointycastle/macs/hmac.dart";
import 'package:web3dart/crypto.dart';

final ECDomainParameters _params = ECCurve_secp256k1();
final BigInt _halfCurveOrder = _params.n >> 1;

class Crypto {
  static Uint8List sign(Uint8List messageHash, Uint8List privateKey) {
    if (privateKey.length != 32) {
      throw 'invalid private key';
    }
    final digest = SHA256Digest();
    final signer = ECDSASigner(null, HMac(digest, 64));
    final key =
        ECPrivateKey(BigInt.parse(bytesToHex(privateKey), radix: 16), _params);
    signer.init(true, PrivateKeyParameter(key));
    var sig = signer.generateSignature(messageHash) as ECSignature;

    if (sig.s.compareTo(_halfCurveOrder) > 0) {
      final canonicalisedS = _params.n - sig.s;
      sig = ECSignature(sig.r, canonicalisedS);
    }

    final publicKey = privateKeyBytesToPublic(privateKey);
    Function eq = const ListEquality().equals;
    int recId = -1;
    for (var i = 0; i < 4; i++) {
      final k = sigToPub(i, sig, messageHash);
      if (eq(k, publicKey)) {
        recId = i;
        break;
      }
    }

    if (recId == -1) {
      throw Exception(
          'Could not construct a recoverable key. This should never happen');
    }
    List<int> signature = [];
    signature.addAll(hexToBytes(sig.r.toRadixString(16).padLeft(64, "0")));
    signature.addAll(hexToBytes(sig.s.toRadixString(16).padLeft(64, "0")));
    signature.add(recId);
    return Uint8List.fromList(signature);
  }

  static Uint8List sigToPub(int recId, ECSignature sig, Uint8List message) {
    ECDomainParameters params = _params;
    final n = params.n;
    final i = BigInt.from(recId ~/ 2);
    final x = sig.r + (i * n);

    //Parameter q of curve
    final prime = BigInt.parse(
        'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
        radix: 16);
    if (x.compareTo(prime) >= 0) return null;

    final R = _decompressKey(x, (recId & 1) == 1, params.curve);
    if (!(R * n).isInfinity) return null;

    final e = bytesToInt(message);

    final eInv = (BigInt.zero - e) % n;
    final rInv = sig.r.modInverse(n);
    final srInv = (rInv * sig.s) % n;
    final eInvrInv = (rInv * eInv) % n;

    final q = (params.G * eInvrInv) + (R * srInv);

    final bytes = q.getEncoded(false);
    return bytes.sublist(1);
  }

  static ECPoint _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
    List<int> x9IntegerToBytes(BigInt s, int qLength) {
      //https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/asn1/x9/X9IntegerConverter.java#L45
      final bytes = intToBytes(s);

      if (qLength < bytes.length) {
        return bytes.sublist(0, bytes.length - qLength);
      } else if (qLength > bytes.length) {
        final tmp = List<int>.filled(qLength, 0);

        final offset = qLength - bytes.length;
        for (var i = 0; i < bytes.length; i++) {
          tmp[i + offset] = bytes[i];
        }

        return tmp;
      }

      return bytes;
    }

    final compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
    compEnc[0] = yBit ? 0x03 : 0x02;
    return c.decodePoint(compEnc);
  }
}

class AESCipher {
  static Uint8List encrypt(Uint8List key, Uint8List data, Uint8List iv) {
    Uint8List hashKey = new Digest("SHA-256").process(key);
    CTRStreamCipher streamCipher = _initCipher(true, hashKey, iv);
    return streamCipher.process(data);
  }

  static Uint8List decrypt(Uint8List key, Uint8List cipherData, Uint8List iv) {
    Uint8List hashKey = new Digest("SHA-256").process(key);
    CTRStreamCipher streamCipher = _initCipher(false, hashKey, iv);
    return streamCipher.process(cipherData);
  }

  static CTRStreamCipher _initCipher(
      bool forEncryption, Uint8List key, Uint8List iv) {
    return CTRStreamCipher(AESFastEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));
  }
}
