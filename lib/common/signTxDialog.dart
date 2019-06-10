import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:veatre/src/api/accountAPI.dart';
import 'package:veatre/src/api/blockAPI.dart';
import 'package:veatre/src/api/transactionAPI.dart';
import 'package:veatre/src/models/account.dart';
import 'package:veatre/src/models/keyStore.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/models/transaction.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/wallets.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/crypto.dart';

class SignTxDialog extends StatefulWidget {
  final List<RawClause> rawClauses;
  SignTxDialog({this.rawClauses});

  @override
  SignTxDialogState createState() => SignTxDialogState();
}

class SignTxDialogState extends State<SignTxDialog> {
  double priority = 0;
  Wallet wallet;

  String vmError = '';
  bool isInsufficient = false;
  double totalGas = 0;
  BigInt spendValue = BigInt.from(0);
  BigInt estimatedFee = BigInt.from(0);
  bool loading = true;
  TextEditingController passwordController = TextEditingController();

  final txGas = 5000;
  final clauseGas = 16000;

  @override
  void initState() {
    super.initState();
    updateSpendValue();
    WalletStorage.readAll().then((walletEntities) {
      if (walletEntities.length > 0) {
        walletFrom(walletEntities[0]).then((wallet) {
          setState(() {
            this.wallet = wallet;
          });
          estimateClauses(wallet.keystore.address).whenComplete(() {
            setState(() {
              this.loading = false;
            });
          });
        });
      } else {
        //TODO create wallet
      }
    });
  }

  updateSpendValue() {
    BigInt value = BigInt.from(0);
    for (RawClause rawClause in widget.rawClauses) {
      value += rawClause.toClause().value;
    }
    setState(() {
      this.spendValue = value;
    });
  }

  estimateClauses(String addr) async {
    double gas = 0;
    gas += txGas;
    List<CallResult> results = await callTx(addr);
    bool hasVmError = false;
    for (CallResult result in results) {
      gas += clauseGas;
      gas += result.gasUsed * 1.2;
      if (result.reverted) {
        hasVmError = true;
        Uint8List data = hexToBytes(result.data);
        String vmErr = '''Transaction may fail/revert
VM error: ${result.vmError}''';
        if (data.length > 4 + 32) {
          DecodingResult<String> err = StringType().decode(data.buffer, 4 + 32);
          vmErr += '''
          ${err.data}''';
        }
        setState(() {
          this.vmError = vmErr;
        });
        break;
      }
    }
    if (!hasVmError) {
      setState(() {
        this.vmError = '';
      });
    }
    setState(() {
      this.totalGas = gas;
    });
    BigInt fee = estimateFee();
    setState(() {
      this.estimatedFee = fee;
    });
    if (this.wallet.account.energy < fee) {
      setState(() {
        this.isInsufficient = true;
      });
    } else {
      setState(() {
        this.isInsufficient = false;
      });
    }
  }

  BigInt estimateFee() {
    return initialBaseGasPrice *
        BigInt.from((1 + priority) * 1e10) *
        BigInt.from(totalGas) ~/
        BigInt.from(1e10);
  }

  Future<List<CallResult>> callTx(String addr) async {
    return AccountAPI.call(
      widget.rawClauses,
      caller: addr,
    );
  }

  Future<Wallet> walletFrom(WalletEntity walletEntity) async {
    Account acc = await AccountAPI.get(walletEntity.keystore.address);
    return Wallet(
      account: acc,
      keystore: walletEntity.keystore,
      name: walletEntity.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              Icons.menu,
              size: 25,
              color: Colors.blue,
            ),
            onPressed: () async {
              final Wallet selectedWallet = await Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new Wallets()),
              );
              if (selectedWallet != null) {
                setState(() {
                  loading = true;
                  this.wallet = selectedWallet;
                });
                await estimateClauses(selectedWallet.keystore.address);
                setState(() {
                  loading = false;
                });
              }
            },
          )
        ],
      ),
      body: ProgressHUD(
        child: Column(
          children: <Widget>[
            Container(
              child: Card(
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 100,
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
                                style: TextStyle(
                                  color: Colors.white,
                                ),
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
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(wallet == null
                              ? '0'
                              : wallet.account.formatBalance()),
                          Container(
                            margin: EdgeInsets.only(left: 5, right: 14),
                            child: Text(
                              'VET',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(wallet == null
                              ? '0'
                              : wallet.account.formatEnergy()),
                          Container(
                            margin: EdgeInsets.only(left: 5, right: 5),
                            child: Text(
                              'VTHO',
                              style: TextStyle(
                                color: Colors.grey,
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
              height: 195,
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Text(
                    'Spend value',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "${Account.fixed2Value(spendValue)}",
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5, right: 9),
                          child: Text(
                            'VET',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
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
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          "${Account.fixed2Value(estimatedFee)}",
                          style: TextStyle(color: Colors.black),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Text(
                            'VTHO',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
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
                    'Priority',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Expanded(
                    child: Slider(
                      onChanged: (priority) async {
                        setState(() {
                          this.priority = priority;
                        });
                        setState(() {
                          this.estimatedFee = estimateFee();
                        });
                      },
                      value: priority,
                      activeColor: Colors.blueAccent,
                      label: "$priority",
                    ),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(right: 15),
                        child: FlatButton(
                          child: Text(
                            'transaction details',
                            style: TextStyle(
                              color: Colors.blueAccent,
                            ),
                          ),
                          onPressed: () async {
                            print('more');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 50,
                          child: FlatButton(
                            color: Colors.blue,
                            child: Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await customAlert(context,
                                  title: Text('Sign transaction'),
                                  content: TextField(
                                    controller: passwordController,
                                    maxLength: 20,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                      hintText: 'Input your password',
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
                                setState(() {
                                  loading = true;
                                });
                                Uint8List privateKey;
                                try {
                                  privateKey = await compute(
                                    decrypt,
                                    Decriptions(
                                        keystore: wallet.keystore,
                                        password: password),
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
                                Block block;
                                try {
                                  block = await BlockAPI.best();
                                } catch (err) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return alert(context, Text("Warnning"),
                                      "network error");
                                }
                                int nonce = Random(DateTime.now().millisecond)
                                    .nextInt(1 << 32);
                                List<Clause> clauses = [];
                                for (RawClause rawClause in widget.rawClauses) {
                                  clauses.add(rawClause.toClause());
                                }
                                Transaction tx = Transaction(
                                  blockRef: BlockRef(number32: block.number),
                                  expiration: 20,
                                  chainTag: mainNetwork,
                                  clauses: clauses,
                                  gasPriceCoef: (255 * priority).toInt(),
                                  gas: totalGas.toInt(),
                                  nonce: nonce,
                                );
                                tx.sign(privateKey);
                                try {
                                  Map<String, dynamic> result =
                                      await TransactionAPI.send(
                                          tx.serialized());
                                  Navigator.of(context).pop(result);
                                } catch (err) {
                                  print("err ${err.message} ");
                                  return alert(context, Text("Error"),
                                      "Sedn transaction failed");
                                } finally {
                                  setState(() {
                                    loading = false;
                                  });
                                }
                              }, cancelAction: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                Navigator.pop(context);
                              });
                            },
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
}
