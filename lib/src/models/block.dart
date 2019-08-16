class Block {
  int number;
  String id;
  int size;
  String parentID;
  int timestamp;
  int gasLimit;
  String beneficiary;
  int gasUsed;
  int totalScore;
  String txsRoot;
  int txsFeatures;
  String stateRoot;
  String receiptsRoot;
  String signer;
  bool isTrunk;
  List<String> transactions;

  Block({
    this.number,
    this.id,
    this.size,
    this.parentID,
    this.timestamp,
    this.gasLimit,
    this.beneficiary,
    this.gasUsed,
    this.totalScore,
    this.txsRoot,
    this.txsFeatures,
    this.stateRoot,
    this.receiptsRoot,
    this.signer,
    this.isTrunk,
    this.transactions,
  });

  factory Block.fromJSON(Map<String, dynamic> parsedJson) {
    List<String> transactions = [];
    List<dynamic> txs = parsedJson['transactions'];
    for (var tx in txs) {
      transactions.add(tx);
    }
    return Block(
      number: parsedJson['number'],
      id: parsedJson['id'],
      size: parsedJson['size'],
      parentID: parsedJson['parentID'],
      timestamp: parsedJson['timestamp'],
      gasLimit: parsedJson['gasLimit'],
      beneficiary: parsedJson['beneficiary'],
      gasUsed: parsedJson['gasUsed'],
      totalScore: parsedJson['totalScore'],
      txsRoot: parsedJson['txsRoot'],
      txsFeatures: parsedJson['txsFeatures'],
      stateRoot: parsedJson['stateRoot'],
      receiptsRoot: parsedJson['receiptsRoot'],
      signer: parsedJson['signer'],
      isTrunk: parsedJson['isTrunk'],
      transactions: transactions,
    );
  }
  get encoded => {
        "number": number,
        "id": id,
        "size": size,
        "parentID": parentID,
        "timestamp": timestamp,
        "gasLimit": gasLimit,
        "beneficiary": beneficiary,
        "gasUsed": gasUsed,
        "totalScore": totalScore,
        "txsRoot": txsRoot,
        "txsFeatures": txsFeatures,
        "stateRoot": stateRoot,
        "receiptsRoot": receiptsRoot,
        "signer": signer,
        "isTrunk": isTrunk,
        "transactions": transactions
      };
}

class BlockHead {
  String id;
  int number;
  int timestamp;
  String parentID;
  int txsFeatures;

  BlockHead({
    this.id,
    this.number,
    this.timestamp,
    this.parentID,
    this.txsFeatures,
  });

  factory BlockHead.fromJSON(Map<String, dynamic> parsedJSON) {
    return BlockHead(
      id: parsedJSON['id'],
      number: parsedJSON['number'],
      timestamp: parsedJSON['timestamp'],
      parentID: parsedJSON['parentID'],
      txsFeatures: parsedJSON['txsFeatures'],
    );
  }

  Map<String, dynamic> get encoded => {
        'id': id,
        'number': number,
        'timestamp': timestamp,
        'parentID': parentID,
        'txsFeatures': txsFeatures,
      };
}
