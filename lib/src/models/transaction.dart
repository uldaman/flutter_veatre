import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:veatre/src/models/Crypto.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;
import 'package:pointycastle/digests/blake2b.dart';

class Transaction {
  static const int Solo = 0xa4;
  static const int TestNetwork = 0x27;
  static const int MainNetwork = 0x4a;

  int chainTag;
  BlockRef blockRef;
  int expiration = 0;
  List<Clause> clauses = [];
  int gasPriceCoef = 0;
  int gas = 0;
  Uint8List dependsOn;
  int nonce = 0;
  List<dynamic> reserved = [];
  Uint8List signature;

  Transaction({
    int chainTag,
    BlockRef blockRef,
    int expiration = 0,
    List<Clause> clauses,
    int gasPriceCoef = 0,
    int gas = 0,
    Uint8List dependsOn,
    int nonce = 0,
    List<dynamic> reserved,
  }) {
    this.chainTag = chainTag;
    this.blockRef = blockRef;
    this.expiration = expiration;
    this.clauses = clauses == null ? [] : clauses;
    this.gasPriceCoef = gasPriceCoef;
    this.gas = gas;
    this.dependsOn = dependsOn == null ? Uint8List(0) : dependsOn;
    this.reserved = reserved == null ? [] : reserved;
  }

  void sign(Uint8List privateKey) {
    this.signature = Crypto.sign(signingHash(), privateKey);
  }

  List<dynamic> unserializedParams() {
    print(
        "${this.chainTag} ${this.blockRef.number64} ${this.expiration} ${this.clauses} ${this.gasPriceCoef} ${this.gas} ${this.dependsOn} ${this.nonce} ${this.reserved}");
    List<dynamic> data = [];
    data.addAll([
      this.chainTag,
      this.blockRef.number64,
      this.expiration,
    ]);
    List<dynamic> clauseList = [];
    for (Clause clause in this.clauses) {
      clauseList.add(clause.encode());
    }
    data.add(clauseList);
    data.addAll([
      this.gasPriceCoef,
      this.gas,
      this.dependsOn,
      this.nonce,
      this.reserved
    ]);
    return data;
  }

  Uint8List unserialized() {
    return rlp.encode(unserializedParams());
  }

  Uint8List signingHash() {
    Uint8List data = unserialized();
    Blake2bDigest blake2b = Blake2bDigest(digestSize: 32);
    return blake2b.process(data);
  }

  Uint8List serialized() {
    List unserializedParams = List.from(this.unserializedParams());
    unserializedParams.add(this.signature);
    return rlp.encode(unserializedParams);
  }
}

class BlockRef {
  int number64;
  BlockRef(int number32) {
    Uint8List data = Uint8List(8);
    ByteData bdata = ByteData.view(data.buffer);
    bdata.setUint32(0, number32);
    this.number64 = bdata.getUint64(0);
  }
}

class Clause {
  Uint8List to;
  BigInt value;
  Uint8List data;

  Clause({Uint8List to, BigInt value, Uint8List data}) {
    this.to = to == null ? Uint8List(0) : to;
    this.value = value == null ? BigInt.zero : value;
    this.data = data == null ? Uint8List(0) : data;
  }

  List<dynamic> encode() {
    return [to, value, data];
  }
}
