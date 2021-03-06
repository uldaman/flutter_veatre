import 'dart:convert';
import 'dart:typed_data';
import 'package:veatre/src/api/AccountAPI.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;
import 'package:pointycastle/digests/blake2b.dart';
import 'package:veatre/src/models/Crypto.dart';
import 'package:web3dart/contracts.dart';

Future<BigInt> initialBaseGasPrice() async {
  final paramABI = [
    {
      "constant": true,
      "inputs": [
        {"name": "_key", "type": "bytes32"}
      ],
      "name": "get",
      "outputs": [
        {"name": "", "type": "uint256"}
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
  ];
  final key = hexToBytes(
      '0x000000000000000000000000000000000000626173652d6761732d7072696365');
  final data = ContractAbi.fromJson(json.encode(paramABI), 'params')
      .functions
      .first
      .encodeCall([key]);
  List<CallResult> res = await AccountAPI.call(
    [
      SigningTxMessage(
        data: '0x' + bytesToHex(data),
        to: '0x0000000000000000000000000000506172616d73',
      )
    ],
    caller: '0x0000000000000000000000000000506172616d73',
  );
  return BigInt.parse(res.first.data.substring(2), radix: 16);
}

class Transaction {
  final int chainTag;

  final BlockRef blockRef;

  final int expiration;

  List<Clause> _clauses = [];
  List<Clause> get clauses {
    return _clauses;
  }

  int gasPriceCoef = 0;
  int gas = 0;

  Uint8List _dependsOn;
  Uint8List get dependsOn {
    return _dependsOn;
  }

  int _nonce = 0;
  int get nonce {
    return _nonce;
  }

  List<dynamic> _reserved = [];
  List<dynamic> get reserved {
    return _reserved;
  }

  Uint8List _signature;
  Uint8List get signature {
    return _signature;
  }

  Transaction({
    this.chainTag,
    this.blockRef,
    this.expiration,
    List<Clause> clauses,
    int gasPriceCoef = 0,
    int gas = 0,
    Uint8List dependsOn,
    int nonce = 0,
    List<dynamic> reserved,
  }) {
    this._clauses = clauses ?? [];
    this.gasPriceCoef = gasPriceCoef;
    this.gas = gas;
    this._dependsOn = dependsOn ?? Uint8List(0);
    this._reserved = reserved ?? [];
  }

  void sign(Uint8List privateKey) {
    this._signature = Crypto.sign(signingHash, privateKey);
  }

  List<dynamic> get _unserializedParams {
    List<dynamic> data = [];
    data.addAll([
      this.chainTag,
      this.blockRef.number,
      this.expiration,
    ]);
    List<dynamic> clauseList = [];
    for (Clause clause in this._clauses) {
      clauseList.add(clause.encode());
    }
    data.add(clauseList);
    data.addAll([
      this.gasPriceCoef,
      this.gas,
      this._dependsOn,
      this._nonce,
      this._reserved
    ]);
    return data;
  }

  Uint8List get _unserialized {
    return rlp.encode(_unserializedParams);
  }

  Uint8List get signingHash {
    Uint8List data = _unserialized;
    Blake2bDigest blake2b = Blake2bDigest(digestSize: 32);
    return blake2b.process(data);
  }

  Uint8List get serialized {
    List unserializedParams = List.from(_unserializedParams);
    if (_signature.length > 0) {
      unserializedParams.add(this._signature);
    }
    return rlp.encode(unserializedParams);
  }

  static int intrinsicGas(List<Clause> clauses) {
    const txGas = 5000;
    const clauseGas = 16000;
    const clauseGasContractCreation = 48000;
    if (clauses.length == 0) {
      return txGas + clauseGas;
    }
    int sum = txGas;
    for (Clause clause in clauses) {
      if (clause.to.length > 0) {
        sum += clauseGas;
      } else {
        sum += clauseGasContractCreation;
      }
      sum += dataGas(clause.data);
    }
    return sum;
  }

  static int dataGas(Uint8List data) {
    const zgas = 4;
    const nzgas = 68;
    int sum = 0;
    for (int i = 0; i < data.length; i++) {
      if (data[i] == 0) {
        sum += zgas;
      } else {
        sum += nzgas;
      }
    }
    return sum;
  }
}

class BlockRef {
  int _number64;
  get number {
    return _number64;
  }

  BlockRef({int number32}) {
    Uint8List data = Uint8List(8);
    ByteData bdata = ByteData.view(data.buffer);
    bdata.setUint32(0, number32);
    this._number64 = bdata.getUint64(0);
  }
}

class Clause {
  Uint8List _to;
  Uint8List get to {
    return _to;
  }

  BigInt _value;
  BigInt get value {
    return _value;
  }

  Uint8List _data;
  Uint8List get data {
    return _data;
  }

  Clause({Uint8List to, BigInt value, Uint8List data}) {
    this._to = to ?? Uint8List(0);
    this._value = value ?? BigInt.zero;
    this._data = data ?? Uint8List(0);
  }

  List<dynamic> encode() {
    return [to, value, data];
  }
}

class SigningTxMessage {
  final String to;

  final String value;

  final String data;

  final String comment;

  SigningTxMessage({this.to, this.value, this.data, this.comment});

  factory SigningTxMessage.fromJSON(Map<String, dynamic> parsedJson) {
    return SigningTxMessage(
      to: parsedJson['to'],
      value: parsedJson['value'] ?? '0',
      data: parsedJson['data'] ?? '0x',
      comment: parsedJson['comment'] ?? '',
    );
  }

  Clause toClause() {
    return Clause(
      to: to != null ? hexToBytes(to) : null,
      value: BigInt.parse(value),
      data: hexToBytes(data),
    );
  }

  Map<String, dynamic> get encoded => {
        to: to,
        value: value,
        data: data,
        comment: comment,
      };
}

class SigningTxOptions {
  bool delegated;
  String signer;
  int gas;
  String dependsOn;
  String link;
  String comment;

  SigningTxOptions({
    this.delegated,
    this.signer,
    this.gas,
    this.dependsOn,
    this.link,
    this.comment,
  });

  factory SigningTxOptions.fromJSON(
      Map<String, dynamic> parsedJSON, String link) {
    return SigningTxOptions(
      delegated: parsedJSON['delegated'],
      signer: parsedJSON['signer'],
      gas: parsedJSON['gas'],
      dependsOn: parsedJSON['dependsOn'],
      link: link,
      comment: parsedJSON['comment'],
    );
  }
}

class SigningTxResponse {
  String txid;
  String signer;

  SigningTxResponse({this.txid, this.signer});

  Map<String, String> get encoded {
    return {
      'txid': txid,
      'signer': signer,
    };
  }
}

class Event {
  final String address;
  final List<String> topics;
  final String data;

  Event({this.address, this.topics, this.data});

  factory Event.fromJSON(Map<String, dynamic> parsedJson) {
    List<String> topics = [];
    for (String topic in parsedJson['topics']) {
      topics.add(topic);
    }
    return Event(
      address: parsedJson['address'],
      topics: topics,
      data: parsedJson['data'],
    );
  }
}

class Transfer {
  final String sender;
  final String recipient;
  final String amount;
  final Meta meta;
  Transfer({this.sender, this.recipient, this.amount, this.meta});

  factory Transfer.fromJSON(Map<String, dynamic> parsedJson) {
    return Transfer(
      sender: parsedJson['sender'],
      recipient: parsedJson['recipient'],
      amount: parsedJson['amount'],
      meta:
          parsedJson['meta'] == null ? null : Meta.fromJSON(parsedJson['meta']),
    );
  }
}

class Meta {
  String blockID;
  int blockNumber;
  int blockTimestamp;
  String txID;
  String txOrigin;
  int clauseIndex;

  Meta({
    this.blockID,
    this.blockNumber,
    this.blockTimestamp,
    this.txID,
    this.txOrigin,
    this.clauseIndex,
  });

  factory Meta.fromJSON(Map<String, dynamic> parsedJSON) {
    return Meta(
      blockID: parsedJSON['blockID'],
      blockNumber: parsedJSON['blockNumber'],
      blockTimestamp: parsedJSON['blockTimestamp'],
      txID: parsedJSON['txID'],
      txOrigin: parsedJSON['txOrigin'],
      clauseIndex: parsedJSON['clauseIndex'],
    );
  }
}

class CallResult {
  final String data;
  final List<Event> events;
  final List<Transfer> transfers;
  final int gasUsed;
  final bool reverted;
  final String vmError;

  CallResult({
    this.data,
    this.events,
    this.transfers,
    this.gasUsed,
    this.reverted,
    this.vmError,
  });

  factory CallResult.fromJSON(Map<String, dynamic> parsedJson) {
    List<Event> events = [];
    for (Map<String, dynamic> event in parsedJson['events']) {
      events.add(Event.fromJSON(event));
    }
    List<Transfer> transfers = [];
    for (Map<String, dynamic> transfer in parsedJson['transfers']) {
      transfers.add(Transfer.fromJSON(transfer));
    }
    return CallResult(
      data: parsedJson['data'],
      events: events,
      transfers: transfers,
      gasUsed: parsedJson['gasUsed'],
      reverted: parsedJson['reverted'],
      vmError: parsedJson['vmError'],
    );
  }
}
