import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:web3dart/contracts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/api/transactionAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/swipeButton.dart';
import 'package:veatre/src/ui/wallets.dart';

class SignTransaction extends StatefulWidget {
  final List<SigningTxMessage> txMessages;
  final SigningTxOptions options;

  SignTransaction({
    this.txMessages,
    this.options,
  });

  @override
  SignTransactionState createState() => SignTransactionState();
}

class SignTransactionState extends State<SignTransaction>
    with SingleTickerProviderStateMixin {
  List<Clause> _clauses = [];
  Wallet wallet;
  WalletEntity walletEntity;
  double priority = 0;
  String vmError = '';
  int totalGas = 0;
  BigInt spendValue = BigInt.from(0);
  BigInt estimatedFee = BigInt.from(0);
  bool loading = true;
  bool isEnable = false;
  int _intrinsicGas = 0;
  BigInt initialBaseGasPrice;

  AnimationController _controller;
  Animation animation;
  SwipeController swipeController = SwipeController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = Tween(begin: 600.0, end: 44.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    super.initState();
    for (SigningTxMessage txMsg in widget.txMessages) {
      _clauses.add(txMsg.toClause());
    }
    _intrinsicGas = Transaction.intrinsicGas(_clauses);
    getWalletEntity(widget.options.signer).then((walletEntity) {
      this.walletEntity = walletEntity;
      _handleHeadChanged().whenComplete(() {
        if (mounted) {
          setState(() {
            this.loading = false;
          });
          Globals.addBlockHeadHandler(_handleHeadChanged);
        }
      });
    });
    updateSpendValue();
  }

  Future<void> _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == Globals.network) {
      await updateBaseGasPrice();
      await updateWallet();
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    _controller.dispose();
    swipeController.dispose();
    super.dispose();
  }

  Future<void> updateWallet() async {
    Account account = await AccountAPI.get(walletEntity.address);
    if (mounted) {
      setState(() {
        this.wallet = Wallet(account: account, entity: walletEntity);
      });
      await estimateGas(walletEntity.address);
    }
  }

  Future<WalletEntity> getWalletEntity(String signer) async {
    if (signer != null) {
      List<WalletEntity> walletEntities = await WalletStorage.readAll();
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity = await WalletStorage.getMainWallet();
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities = await WalletStorage.readAll();
    return walletEntities[0];
  }

  updateSpendValue() {
    BigInt value = BigInt.from(0);
    for (SigningTxMessage txMsg in widget.txMessages) {
      value += txMsg.toClause().value;
    }
    setState(() {
      this.spendValue = value;
    });
  }

  updateBaseGasPrice() async {
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
    );
    initialBaseGasPrice = BigInt.parse(res.first.data);
  }

  estimateGas(String addr) async {
    int gas = _intrinsicGas;
    List<CallResult> results = await callTx(addr, widget.options.gas);
    String vmErr = '';
    for (CallResult result in results) {
      gas += (result.gasUsed.toDouble() * 1.2).toInt();
      if (result.reverted) {
        Uint8List data = hexToBytes(result.data);
        vmErr = '''Transaction may fail/revert
VM error: ${result.vmError}''';
        if (data.length > 4 + 32) {
          DecodingResult<String> err = StringType().decode(data.buffer, 4 + 32);
          vmErr += '''
          ${err.data}''';
        }
        break;
      }
    }
    if (mounted) {
      setState(() {
        this.vmError = vmErr;
      });
    }
    this.totalGas = widget.options.gas ?? gas;
    if (mounted) {
      setState(() {
        this.estimatedFee = estimateFee(initialBaseGasPrice);
      });
    }
  }

  Future<void> showWallets() async {
    final WalletEntity walletEntity = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Wallets(),
      ),
    );
    if (walletEntity != null) {
      this.walletEntity = walletEntity;
      setState(() {
        loading = true;
      });
      await updateWallet();
      setState(() {
        loading = false;
      });
    }
  }

  BigInt estimateFee(BigInt initialBaseGasPrice) {
    return initialBaseGasPrice *
        BigInt.from((1 + priority) * 1e10) *
        BigInt.from(totalGas) ~/
        BigInt.from(1e10);
  }

  Future<List<CallResult>> callTx(String addr, int gas) async {
    return AccountAPI.call(
      widget.txMessages,
      caller: addr,
      gas: gas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text('Sign Transaction'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            size: 25,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              size: 25,
            ),
            onPressed: () async {
              await showWallets();
            },
          )
        ],
      ),
      body: ProgressHUD(
        child: Column(
          children: <Widget>[
            vmError != ''
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: Colors.orangeAccent,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: <Widget>[
                              Container(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.limeAccent,
                                  size: 18,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  vmError,
                                  textAlign: TextAlign.left,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(),
            GestureDetector(
              child: Container(
                child: Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 85,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF81269D),
                              const Color(0xFFEE112D)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Container(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  walletEntity?.name ?? '--',
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 15, right: 15),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                '0x' + (walletEntity.address ?? ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet?.account?.formatBalance ?? '--'),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 14),
                              child: Text(
                                'VET',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .accentTextTheme
                                      .title
                                      .color,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(wallet?.account?.formatEnergy ?? '--'),
                            Container(
                              margin: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                'VTHO',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .accentTextTheme
                                      .title
                                      .color,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: 170,
              ),
              onTap: () async {
                await showWallets();
              },
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Spend value',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "${fixed2Value(spendValue)}",
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 9),
                          child: Text(
                            'VET',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .title
                                    .color,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Estimated fee',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          estimatedFee != null
                              ? "${fixed2Value(estimatedFee)}"
                              : '--',
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VTHO',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .title
                                    .color,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Accelaration',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Slider(
                          activeColor: Colors.blueAccent,
                          onChanged: (value) async {
                            setState(() {
                              this.priority = value;
                              this.estimatedFee =
                                  estimateFee(initialBaseGasPrice);
                            });
                            setState(() {});
                          },
                          value: priority,
                        )
                      ],
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            widget.options.comment != null
                ? Container(
                    margin: EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('${widget.options.comment}'),
                        ),
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                  )
                : Row(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: buildClause,
                      itemCount: widget.txMessages.length,
                      physics: ClampingScrollPhysics(),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 44,
                            ),
                            child: SizedBox(
                              width: animation.value,
                              child: SwipeButton(
                                swipeController: swipeController,
                                content: Center(
                                  child: Text(
                                    'Slide to send transaction',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(22)),
                                height: 44,
                                onDragEnd: () async {
                                  swipeController.valueWith(
                                    enabled: false,
                                    shouldLoading: true,
                                    rollBack: true,
                                  );
                                  await _controller.forward();
                                  Uint8List privateKey =
                                      await walletEntity.decryptPrivateKey(
                                    Globals.masterPasscodes,
                                  );
                                  int nonce = Random(DateTime.now().millisecond)
                                      .nextInt(1 << 32);
                                  int chainTag =
                                      Globals.network == Network.MainNet
                                          ? 0x4a
                                          : 0x27;
                                  final head = Globals.head();
                                  Transaction tx = Transaction(
                                    blockRef: BlockRef(number32: head.number),
                                    expiration: 18,
                                    chainTag: chainTag,
                                    clauses: _clauses,
                                    gasPriceCoef: (255 * priority).toInt(),
                                    gas: totalGas,
                                    dependsOn: widget.options.dependsOn ??
                                        Uint8List(0),
                                    nonce: nonce,
                                  );
                                  tx.sign(privateKey);
                                  try {
                                    Map<String, dynamic> result =
                                        await TransactionAPI.send(
                                            tx.serialized);
                                    String comment = 'Unkown';
                                    if (widget.txMessages.length > 1) {
                                      comment = 'Batch Call';
                                    } else if (widget.txMessages.length == 1) {
                                      SigningTxMessage msg =
                                          widget.txMessages.first;
                                      comment = msg.data.length == 2
                                          ? 'Transfer'
                                          : msg.to.length == 2
                                              ? 'Create'
                                              : 'Call';
                                    }
                                    List<Map<String, dynamic>> content = [];
                                    for (final clause in widget.txMessages) {
                                      content.add(clause.encoded);
                                    }
                                    await ActivityStorage.insert(
                                      Activity(
                                        hash: result['id'],
                                        block: head.number,
                                        content: json.encode({
                                          'messages': content,
                                          'fee': estimatedFee.toRadixString(16),
                                          'gas': totalGas,
                                          'priority': priority,
                                        }),
                                        link: widget.options.link,
                                        address: walletEntity.address,
                                        type: ActivityType.Transaction,
                                        comment: comment,
                                        timestamp: head.timestamp,
                                        network: Globals.network,
                                        status: ActivityStatus.Pending,
                                      ),
                                    );
                                    await WalletStorage.setMainWallet(
                                        walletEntity);
                                    swipeController.valueWith(
                                      enabled: true,
                                      shouldLoading: false,
                                      rollBack: true,
                                    );
                                    Navigator.of(context).pop(
                                      SigningTxResponse(
                                        txid: result['id'],
                                        signer: '0x' + walletEntity.address,
                                      ),
                                    );
                                  } catch (err) {
                                    swipeController.valueWith(
                                      enabled: true,
                                      shouldLoading: false,
                                      rollBack: true,
                                    );
                                    if (err.response != null) {
                                      await alert(
                                          context,
                                          Text("Send transaction failed"),
                                          "${err.response.data}");
                                    }
                                    await _controller.reverse();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
        isLoading: loading,
      ),
    );
  }

  Widget buildClause(BuildContext context, int index) {
    SigningTxMessage txMessage = widget.txMessages[index];
    Widget clauseCard = Padding(
      padding: EdgeInsets.all(5),
      child: Card(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  margin: EdgeInsets.only(top: 15, left: 10),
                  child: Text(
                    'To',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Text(txMessage.to),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 10),
                  width: 80,
                  child: Text(
                    'Value',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text("${fixed2Value(BigInt.parse(txMessage.value))}"),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VET',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .title
                                    .color,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 15, left: 10),
                  width: 80,
                  child: Text(
                    'Inpu data',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 15, left: 5, right: 10),
                    child: Text(txMessage.data),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 80,
                  margin: EdgeInsets.only(top: 15, left: 10, bottom: 15),
                  child: Text(
                    'Comment',
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.title.color,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        top: 15, left: 5, right: 10, bottom: 15),
                    child: Text(txMessage.comment),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return clauseCard;
  }
}
