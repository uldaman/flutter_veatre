import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/common/globals.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/api/transactionAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/networkStorage.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/storage/activitiyStorage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:web3dart/contracts.dart';
import 'package:veatre/src/utils/common.dart';

class SignTxDialog extends StatefulWidget {
  final List<SigningTxMessage> txMessages;
  final SigningTxOptions options;
  final Network network;

  SignTxDialog({
    this.txMessages,
    this.options,
    this.network,
  });

  @override
  SignTxDialogState createState() => SignTxDialogState();
}

class SignTxDialogState extends State<SignTxDialog> {
  List<Clause> _clauses = [];
  int _intrinsicGas = 0;
  Wallet wallet;
  WalletEntity walletEntity;
  double priority = 0;
  String vmError = '';
  bool isInsufficient = false;
  int totalGas = 0;
  BigInt spendValue = BigInt.from(0);
  BigInt estimatedFee = BigInt.from(0);
  bool loading = true;
  TextEditingController passwordController = TextEditingController();
  final txGas = 5000;
  final clauseGas = 16000;

  @override
  void initState() {
    super.initState();
    for (SigningTxMessage txMsg in widget.txMessages) {
      _clauses.add(txMsg.toClause());
    }
    _intrinsicGas = Transaction.intrinsicGas(_clauses);
    getWalletEntity(widget.options.signer).then((walletEntity) {
      this.walletEntity = walletEntity;
      updateWallet().whenComplete(() {
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

  void _handleHeadChanged() async {
    if (Globals.blockHeadForNetwork.network == widget.network) {
      await updateWallet();
    }
  }

  @override
  void dispose() {
    Globals.removeBlockHeadHandler(_handleHeadChanged);
    super.dispose();
  }

  Future<void> updateWallet() async {
    Wallet wallet = await walletFrom(walletEntity);
    if (mounted) {
      setState(() {
        this.wallet = wallet;
      });
      await estimateGas(wallet.keystore.address);
    }
  }

  Future<WalletEntity> getWalletEntity(String signer) async {
    if (signer != null) {
      List<WalletEntity> walletEntities =
          await WalletStorage.readAll(widget.network);
      for (WalletEntity walletEntity in walletEntities) {
        if ('0x' + walletEntity.keystore.address == signer) {
          return walletEntity;
        }
      }
    }
    WalletEntity mianWalletEntity =
        await WalletStorage.getMainWallet(widget.network);
    if (mianWalletEntity != null) {
      return mianWalletEntity;
    }
    List<WalletEntity> walletEntities =
        await WalletStorage.readAll(widget.network);
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
    BigInt fee = estimateFee();
    if (mounted) {
      setState(() {
        this.estimatedFee = fee;
        this.isInsufficient = this.wallet.account.energy < fee;
      });
    }
  }

  Future<void> showWallets() async {
    final WalletEntity walletEntity = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Wallets(
          network: widget.network,
        ),
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

  Future<Wallet> walletFrom(WalletEntity walletEntity) async {
    Account acc =
        await AccountAPI.get(walletEntity.keystore.address, widget.network);
    return Wallet(
      account: acc,
      keystore: walletEntity.keystore,
      name: walletEntity.name,
    );
  }

  BigInt estimateFee() {
    return initialBaseGasPrice *
        BigInt.from((1 + priority) * 1e10) *
        BigInt.from(totalGas) ~/
        BigInt.from(1e10);
  }

  Future<List<CallResult>> callTx(String addr, int gas) async {
    return AccountAPI.call(
      widget.txMessages,
      widget.network,
      caller: addr,
      gas: gas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      resizeToAvoidBottomPadding: false,
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
            isInsufficient
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: Colors.orangeAccent,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.error,
                                color: Colors.limeAccent,
                                size: 18,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  "Insufficient energy",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(),
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
                                  wallet == null ? '' : wallet.name,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.only(left: 15, right: 15),
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                wallet == null
                                    ? ''
                                    : '0x' + wallet.keystore.address,
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
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatBalance),
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
                            Text(wallet == null
                                ? '0'
                                : wallet.account.formatEnergy),
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
                          "${fixed2Value(estimatedFee)}",
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
                            });
                            setState(() {
                              this.estimatedFee = estimateFee();
                            });
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
                        child: Container(
                          height: 50,
                          child: FlatButton(
                            disabledColor: Colors.grey[400],
                            color: Colors.blue,
                            child: Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: !loading &&
                                    vmError == '' &&
                                    !isInsufficient
                                ? () async {
                                    await customAlert(context,
                                        title: Text('Sign transaction'),
                                        content: TextField(
                                          controller: passwordController,
                                          maxLength: 20,
                                          obscureText: true,
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            hintText: 'Input your password',
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .textTheme
                                                .body1
                                                .color,
                                          ),
                                        ), confirmAction: () async {
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                      String password = passwordController.text;
                                      if (password.isEmpty) {
                                        return alert(
                                          context,
                                          Text('Warnning'),
                                          "Password can't be empty",
                                        );
                                      }
                                      Navigator.pop(context);
                                      passwordController.clear();
                                      setState(() {
                                        loading = true;
                                      });
                                      Uint8List privateKey;
                                      try {
                                        privateKey = await BipKeyDerivation
                                            .decryptedByKeystore(
                                          wallet.keystore,
                                          password,
                                        );
                                      } catch (err) {
                                        setState(() {
                                          loading = false;
                                        });
                                        return alert(
                                          context,
                                          Text('Warnning'),
                                          "Password Invalid",
                                        );
                                      }
                                      int nonce =
                                          Random(DateTime.now().millisecond)
                                              .nextInt(1 << 32);
                                      int chainTag =
                                          widget.network == Network.MainNet
                                              ? mainNetwork
                                              : testNetwork;
                                      final head = Globals.head(widget.network);
                                      Transaction tx = Transaction(
                                        blockRef:
                                            BlockRef(number32: head.number),
                                        expiration: 30,
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
                                        await WalletStorage.setMainWallet(
                                          WalletEntity(
                                            keystore: wallet.keystore,
                                            name: wallet.name,
                                          ),
                                          widget.network,
                                        );
                                        Map<String, dynamic> result =
                                            await TransactionAPI.send(
                                                tx.serialized, widget.network);
                                        String comment = 'Empty transaction';
                                        if (widget.txMessages.length > 1) {
                                          comment =
                                              'Perform a batch of clauses';
                                        } else if (widget.txMessages.length ==
                                            1) {
                                          SigningTxMessage msg =
                                              widget.txMessages.first;
                                          comment = msg.data.length > 2
                                              ? 'Make a contract call'
                                              : 'Transfer VET';
                                        }
                                        await ActivityStorage.insert(
                                          Activity(
                                            hash: result['id'],
                                            block: head.number,
                                            content: json.encode({
                                              'amount': fixed2Value(spendValue),
                                              'fee': fixed2Value(estimatedFee),
                                              'gas': totalGas,
                                              'priority': priority,
                                            }),
                                            link: widget.options.link,
                                            walletName: wallet.name,
                                            type: ActivityType.Transaction,
                                            comment: comment,
                                            timestamp: head.timestamp,
                                            net: widget.network ==
                                                    Network.MainNet
                                                ? 0
                                                : 1,
                                            status: ActivityStatus.Pending,
                                          ),
                                        );
                                        Navigator.of(context).pop(
                                          SigningTxResponse(
                                            txid: result['id'],
                                            signer:
                                                '0x' + wallet.keystore.address,
                                          ),
                                        );
                                        setState(() {
                                          loading = false;
                                        });
                                      } catch (err) {
                                        setState(() {
                                          loading = false;
                                        });
                                        alert(
                                            context,
                                            Text("Send transaction failed"),
                                            "${err.response.data}");
                                      }
                                    }, cancelAction: () async {
                                      passwordController.clear();
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                    });
                                  }
                                : null,
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
