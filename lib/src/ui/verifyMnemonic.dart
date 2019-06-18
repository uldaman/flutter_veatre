import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/storage/storage.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/models/keyStore.dart';

class VerifyMnemonic extends StatefulWidget {
  static const routeName = '/wallet/mnemonic/verification';

  VerifyMnemonic() : super();

  @override
  VerifyMnemonicState createState() => VerifyMnemonicState();
}

class TopButton {
  String word;
  bool isSelected = false;
  int selectedIndex;
  int page;
  Future<void> Function(int page, int index, String word) action;

  TopButton(this.page, this.selectedIndex, this.action);
  Widget buildChild(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) * 0.25,
      child: this.isSelected
          ? RaisedButton(
              padding: EdgeInsets.all(0),
              color: Colors.green,
              onPressed: () async {
                if (this.isSelected) {
                  await action(this.page, this.selectedIndex, this.word);
                  this.isSelected = false;
                }
              },
              child: Text(
                this.word,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            )
          : RaisedButton(
              padding: EdgeInsets.all(0),
              color: Colors.cyan,
              onPressed: () async {},
              child: Text(
                '——',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }
}

class BottomButton {
  String word;
  bool isEnabled = true;
  int index;
  int page;
  Future<bool> Function(int page, int index, String word) action;
  BottomButton(this.page, this.index, this.word, this.action);

  Widget buildChild(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) * 0.25,
      child: RaisedButton(
        padding: EdgeInsets.all(0),
        color: this.isEnabled ? Colors.blue : Colors.grey,
        onPressed: () async {
          if (this.isEnabled) {
            bool isActs = await action(this.page, this.index, this.word);
            if (isActs) {
              this.isEnabled = false;
            }
          }
        },
        child: Text(
          this.word,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class VerifyMnemonicState extends State<VerifyMnemonic> {
  List<List<TopButton>> topBtns = [];
  List<List<BottomButton>> bottomBtns = [];
  bool loading = false;
  int currentPage = 0;
  bool computing = false;
  KeyStore _keystore;

  Future<KeyStore> computeKeystore(
      MnemonicDecriptions mnemonicDecriptions) async {
    setState(() {
      this.computing = true;
    });
    KeyStore keystore = await compute(
      decryptMnemonic,
      mnemonicDecriptions,
    );
    setState(() {
      this._keystore = keystore;
    });
    return keystore;
  }

  @override
  Widget build(BuildContext context) {
    final WalletArguments args = ModalRoute.of(context).settings.arguments;
    if (!computing) {
      computeKeystore(
        MnemonicDecriptions(
          mnemonic: args.mnemonics.join(" "),
          password: args.password,
        ),
      );
    }
    if (this.topBtns.length < 3) {
      for (int i = 0; i < 3; i++) {
        List<TopButton> pageTopBtns = [];
        for (int k = i * 4; k < (i + 1) * 4; k++) {
          pageTopBtns
              .add(TopButton(i, k, (int page, int index, String word) async {
            return setState(() {
              this.bottomBtns[page][index].isEnabled = true;
            });
          }));
        }
        this.topBtns.add(pageTopBtns);

        List<BottomButton> pageBottomBtns = [];
        List<String> words = args.randomWordsList[i];
        for (int j = 0; j < words.length; j++) {
          pageBottomBtns.add(BottomButton(i, j, words[j],
              (int page, int selectedIndex, String word) async {
            for (int i = 0; i < this.topBtns[page].length; i++) {
              TopButton tb = this.topBtns[page][i];
              if (!tb.isSelected) {
                setState(() {
                  tb.word = word;
                  tb.selectedIndex = selectedIndex;
                  tb.page = page;
                  tb.isSelected = true;
                });
                return true;
              }
            }
            return false;
          }));
        }
        this.bottomBtns.add(pageBottomBtns);
      }
    }

    List<Widget> pages = [];
    for (int i = 0; i < 3; i++) {
      pages.add(this.buildPage(i, context));
    }

    PageController pageController = PageController(initialPage: 0);

    PageView pageView = PageView(
      scrollDirection: Axis.horizontal,
      controller: pageController,
      physics: new ClampingScrollPhysics(),
      onPageChanged: (int page) async {
        setState(() {
          this.currentPage = page;
        });
      },
      children: pages,
    );

    double width = MediaQuery.of(context).size.width - 40;
    return ProgressHUD(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Verify Mnemonic'),
          centerTitle: true,
        ),
        body: Center(
          child: Container(
            height: 600,
            child: Column(
              children: <Widget>[
                Container(
                  height: 25,
                  width: width,
                  margin: EdgeInsets.all(30),
                  child: Text(
                    "Select your mnemonic phase",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  height: 260,
                  child: pageView,
                ),
                Container(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text("${currentPage + 1}/3"),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: currentPage > 0 ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        if (this.currentPage > 0) {
                          pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        if (this.currentPage < 2) {
                          await pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        } else {
                          setState(() {
                            this.loading = true;
                          });
                          if (verify(args.mnemonics)) {
                            await Future.delayed(Duration(seconds: 3));
                            while (_keystore == null) {
                              await Future.delayed(Duration(seconds: 1));
                            }
                            // KeyStore keystore = await compute(
                            //   decryptMnemonic,
                            //   MnemonicDecriptions(
                            //     mnemonic: args.mnemonics.join(" "),
                            //     password: args.password,
                            //   ),
                            // );
                            await WalletStorage.write(
                              walletEntity: WalletEntity(
                                name: args.walletName,
                                keystore: _keystore,
                              ),
                              isMainWallet: true,
                            );
                            setState(() {
                              this.loading = false;
                            });
                            Navigator.popUntil(context,
                                ModalRoute.withName(ManageWallets.routeName));
                          } else {
                            setState(() {
                              this.loading = false;
                            });
                            await alert(context, Text("Warnning"),
                                "Mnemonic phase verfied failed");
                          }
                        }
                      },
                    )
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
      isLoading: loading,
    );
  }

  Widget buildPage(int page, BuildContext context) {
    List<Widget> tbtns = [];
    for (int i = 0; i < 4; i++) {
      tbtns.add(this.topBtns[page][i].buildChild(context));
    }
    List<Widget> bottomFirstRow = [];
    List<Widget> bottomSecondRow = [];
    List<Widget> bottomThirdRow = [];
    List<BottomButton> bbtns = this.bottomBtns[page];

    for (int i = 0; i < 12; i++) {
      Widget widget = bbtns[i].buildChild(context);
      if (i < 4) {
        bottomFirstRow.add(widget);
      } else if (i < 8) {
        bottomSecondRow.add(widget);
      } else {
        bottomThirdRow.add(widget);
      }
    }
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tbtns,
          ),
          SizedBox(
            height: 60,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bottomFirstRow,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bottomSecondRow,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bottomThirdRow,
          ),
        ],
      ),
    );
  }

  bool verify(List<String> mnemonic) {
    for (int page = 0; page < 3; page++) {
      List<TopButton> btns = this.topBtns[page];
      for (int index = 0; index < 4; index++) {
        if (mnemonic[page * 4 + index] != btns[index].word) {
          return false;
        }
      }
    }
    return true;
  }
}
