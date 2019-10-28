import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:web3dart/crypto.dart';
import 'package:pointycastle/api.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';

String abbreviate(String str, {int head = 0, int tail = 0}) {
  int len = str.length;
  if (head > len || tail > len) {
    return str;
  }
  return '${str.substring(0, head)}…${str.substring(len - tail, len)}';
}

String zero2(word) {
  if (word.length == 1)
    return '0' + word;
  else
    return word;
}

bool isSurrogatePair(String msg, i) {
  if ((msg.codeUnitAt(i) & 0xFC00) != 0xD800) {
    return false;
  }
  if (i < 0 || i + 1 >= msg.length) {
    return false;
  }
  return (msg.codeUnitAt(i + 1) & 0xFC00) == 0xDC00;
}

List<int> toArray(String msg, [String enc]) {
  if (enc == 'hex') {
    List<int> hexRes = new List();
    msg = msg.replaceAll(new RegExp("[^a-z0-9]"), '');
    if (msg.length % 2 != 0) msg = '0' + msg;
    for (var i = 0; i < msg.length; i += 2) {
      var cul = msg[i] + msg[i + 1];
      var result = int.parse(cul, radix: 16);
      hexRes.add(result);
    }
    return hexRes;
  } else {
    List<int> noHexRes = new List();
    for (var i = 0; i < msg.length; i++) {
      var c = msg.codeUnitAt(i);
      var hi = c >> 8;
      var lo = c & 0xff;
      if (hi > 0) {
        noHexRes.add(hi);
        noHexRes.add(lo);
      } else {
        noHexRes.add(lo);
      }
    }

    return noHexRes;
  }
}

List<int> randomBytes(int byteLength) {
  Random random = new Random.secure();
  return RandomBridge(random).nextBytes(byteLength);
}

String randomHex(int hexLength) {
  return bytesToHex(randomBytes(hexLength ~/ 2));
}

String get defaultDerivationPath {
  return "m/44'/818'/0'/0/0";
}

String fixed2Value(BigInt value) {
  double v = (value / BigInt.from(1e18)).toDouble();
  String fixed2 = v.toStringAsFixed(2);
  if (fixed2.split('.')[1].endsWith('0')) {
    String fixed1 = v.toStringAsFixed(1);
    if (fixed1.split('.')[1].endsWith('0')) {
      return v.toStringAsFixed(0);
    }
    return fixed1;
  }
  return fixed2;
}

String bytesToHex(Uint8List data) {
  return hex.encode(data);
}

Uint8List hexToBytes(String hexStr) {
  String h = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
  return hex.decode(h);
}

Future<String> addressFrom(String mnemonic) async {
  Uint8List privateKey = await BipKeyDerivation.decryptedByMnemonic(
      mnemonic, defaultDerivationPath);
  Uint8List publicKey = await BipKeyDerivation.privateToPublic(privateKey);
  final addr = await BipKeyDerivation.publicToAddress(publicKey);
  return bytesToHex(addr);
}

String formatNum(String num) {
  List<String> splitNum = num.split('.');
  List<String> v = splitNum.first.split('');
  for (int i = splitNum.first.length - 1, index = 0; i >= 0; i--, index++) {
    if (index % 3 == 0 && index != 0) v[i] = v[i] + ',';
  }
  String s = v.join('');
  if (splitNum.length > 1) {
    s += '.${splitNum[1]}';
  }
  return s;
}

String shotHex(String hex) {
  return (hex == null || hex.length < 8)
      ? '0x'
      : '0x${hex.substring(0, 4)}...${hex.substring(hex.length - 4, hex.length)}';
}

class RandomBridge implements SecureRandom {
  Random dartRandom;

  RandomBridge(this.dartRandom);

  @override
  String get algorithmName => 'DartRandom';

  @override
  BigInt nextBigInteger(int bitLength) {
    final fullBytes = bitLength ~/ 8;
    final remainingBits = bitLength % 8;

    // Generate a number from the full bytes. Then, prepend a smaller number
    // covering the remaining bits.
    final main = bytesToInt(nextBytes(fullBytes));
    final additional = dartRandom.nextInt(1 << remainingBits);
    return main + (BigInt.from(additional) << (fullBytes * 8));
  }

  @override
  Uint8List nextBytes(int count) {
    final list = Uint8List(count);

    for (var i = 0; i < list.length; i++) {
      list[i] = nextUint8();
    }

    return list;
  }

  @override
  int nextUint16() => dartRandom.nextInt(1 << 16);

  @override
  int nextUint32() => dartRandom.nextInt(1 << 32);

  @override
  int nextUint8() => dartRandom.nextInt(1 << 8);

  @override
  void seed(CipherParameters params) {
    // ignore, dartRandom will already be seeded if wanted
  }
}
