class Account {
  BigInt balance;
  BigInt energy;
  bool hasCode;

  static final unit = BigInt.from(1e18);

  Account({this.balance, this.energy, this.hasCode});

  String formatBalance() {
    double b = (this.balance / unit).toDouble();
    String fixed2 = b.toStringAsFixed(2);
    if (fixed2.split('.')[1].endsWith('0')) {
      String fixed1 = b.toStringAsFixed(1);
      if (fixed1.split('.')[1].endsWith('0')) {
        return b.toStringAsFixed(0);
      }
      return fixed1;
    }
    return fixed2;
  }

  String formatEnergy() {
    double ene = (this.energy / unit).toDouble();
    String fixed2 = ene.toStringAsFixed(2);
    if (fixed2.split('.')[1].endsWith('0')) {
      String fixed1 = ene.toStringAsFixed(1);
      if (fixed1.split('.')[1].endsWith('0')) {
        return ene.toStringAsFixed(0);
      }
      return fixed1;
    }
    return fixed2;
  }

  factory Account.fromJSON(Map<String, dynamic> parsedJson) {
    return Account(
      // address: parsedJson['address'] == null ? '' : parsedJson['address'],
      balance: parsedJson['balance'] == null
          ? BigInt.from(0)
          : BigInt.parse(parsedJson['balance']),
      energy: parsedJson['energy'] == null
          ? BigInt.from(0)
          : BigInt.parse(parsedJson['energy']),
      hasCode: parsedJson['hasCode'],
    );
  }
}
