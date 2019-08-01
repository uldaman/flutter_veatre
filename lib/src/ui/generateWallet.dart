import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:bip_key_derivation/keystore.dart';
import 'package:bip_key_derivation/bip_key_derivation.dart';
import 'package:veatre/src/storage/walletStorage.dart';
import 'package:veatre/src/ui/alert.dart';
import 'package:veatre/src/ui/progressHUD.dart';
import 'package:veatre/src/ui/manageWallets.dart';
import 'package:veatre/src/utils/common.dart';

class GenerateWallet extends StatefulWidget {
  final String walletName;
  final String password;

  GenerateWallet({this.walletName, this.password});
  @override
  GenerateWalletState createState() => GenerateWalletState();
}

class GenerateWalletState extends State<GenerateWallet> {
  bool loading = false;
  int currentPage = 0;
  List<String> mnemonics = [];
  List<Widget> wordWidgets = [];
  List<WordPage> wordPages = [];

  @override
  void initState() {
    super.initState();
    generateWords();
  }

  Future<List<String>> get words async {
    String words = await rootBundle
        .loadString("assets/resource/en-mnemonic-word-list.txt");
    return words.split("\n");
  }

  generateWords() async {
    setState(() {
      loading = true;
    });
    String mnemonic = await BipKeyDerivation.generateRandomMnemonic(128);
    this.mnemonics = mnemonic.split(" ");
    List<Widget> wordWidgets = [];
    for (int i = 0; i < mnemonics.length; i++) {
      String word = mnemonics[i];
      Widget widget = Container(
        child: Text(
          word,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        width: (MediaQuery.of(context).size.width - 70) * 0.25,
      );
      wordWidgets.add(widget);
    }
    setState(() {
      this.wordWidgets = wordWidgets;
    });

    List<String> words = await this.words;
    List<WordPage> wordPages = [];
    for (int i = 0; i < 3; i++) {
      List<String> pageWords = mnemonics.sublist(i * 4, (i + 1) * 4);
      List<WaitingWord> pageWaitingWords = [];
      for (int j = 0; j < pageWords.length; j++) {
        Function action = (int page, int index, int selectedIndex, String word,
            bool isSelected) async {
          if (isSelected) {
            setState(() {
              wordPages[page].waitingWords[index].isSelected = false;
              wordPages[page].randomWords[selectedIndex].isAvailable = true;
            });
          }
        };
        pageWaitingWords.add(
          WaitingWord(
            word: pageWords[j],
            page: i,
            index: j,
            isSelected: false,
            action: action,
          ),
        );
      }
      List<String> randoms = List.from(pageWords);
      while (randoms.length < 12) {
        Random random = Random();
        int index = random.nextInt(words.length);
        String word = words[index];
        if (!pageWords.contains(word)) {
          randoms.add(word);
        }
      }
      randoms.shuffle();

      List<RandomWord> pageRandomWords = [];
      for (int k = 0; k < randoms.length; k++) {
        Function action = (
          int page,
          int index,
          String word,
          bool isAvailable,
        ) async {
          if (isAvailable) {
            for (WaitingWord waitingWord in wordPages[page].waitingWords) {
              if (!waitingWord.isSelected) {
                setState(() {
                  waitingWord.isSelected = true;
                  waitingWord.selectedIndex = index;
                  waitingWord.word = word;
                  wordPages[page].randomWords[index].isAvailable = false;
                });
                break;
              }
            }
          }
        };
        pageRandomWords.add(RandomWord(
          word: randoms[k],
          page: i,
          index: k,
          isAvailable: true,
          action: action,
        ));
      }
      wordPages.add(
        WordPage(
          waitingWords: pageWaitingWords,
          randomWords: pageRandomWords,
        ),
      );
    }
    setState(() {
      this.wordPages = wordPages;
    });
    setState(() {
      loading = false;
    });
  }

  List<Widget> buildWordCard() {
    List<Widget> words = [];
    if (wordWidgets.length == 12) {
      for (int i = 0; i < 3; i++) {
        words.add(
          Container(
            padding: EdgeInsets.only(top: i == 0 ? 15 : 0, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: wordWidgets.sublist(i * 4, (i + 1) * 4),
            ),
          ),
        );
      }
    }
    return words;
  }

  List<Widget> buildWordPages(BuildContext context) {
    List<Widget> pages = [];
    for (WordPage wordPage in wordPages) {
      List<Widget> waitingWords = [];
      for (WaitingWord waitingWord in wordPage.waitingWords) {
        waitingWords.add(waitingWord.buildChild(context));
      }
      List<Widget> rows = [];
      if (wordPage.randomWords.length == 12) {
        for (int i = 0; i < 3; i++) {
          List<RandomWord> rowRandomWords =
              wordPage.randomWords.sublist(i * 4, (i + 1) * 4);
          List<Widget> row = List.from(
            rowRandomWords.map((randomWord) {
              return randomWord.buildChild(context);
            }),
          );
          rows.add(
            Row(
              children: row,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
            ),
          );
        }
      }
      Widget page = Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(left: 10, right: 10),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: waitingWords,
            ),
            SizedBox(
              height: 40,
            ),
            Column(
              children: rows,
            ),
          ],
        ),
      );
      pages.add(page);
    }
    return pages;
  }

  bool verify(List<String> mnemonic) {
    List<String> selectedWords = [];
    for (WordPage wordPage in wordPages) {
      for (WaitingWord waitingWord in wordPage.waitingWords) {
        selectedWords.add(waitingWord.word);
      }
    }
    return mnemonic.join(' ') == selectedWords.join(' ');
  }

  @override
  Widget build(BuildContext context) {
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
      children: buildWordPages(context),
    );
    return ProgressHUD(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Generate Mnemonic'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.all(10),
                child: Card(
                  color: Colors.grey[100],
                  child: Container(
                    margin: EdgeInsets.all(10),
                    child: Text(
                        "Mnemonic phrase is a list of words that store all the information needed for the recovery of a wallet. Please write it down on paper.if you forget the private key, You would be able to upload the same wallet and use the paper backup copy to get your tokens back. As every owner of a mnemonic phrase gets an access to the wallet, it must be kept very carefully."),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(10),
                child: Card(
                  color: Colors.grey[100],
                  child: Column(
                    children: buildWordCard(),
                  ),
                ),
              ),
              Container(
                height: 25,
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.all(30),
                child: Text(
                  currentPage == 0
                      ? "Select first row's mnemonic phase"
                      : currentPage == 1
                          ? "Select second row's mnemonic phase"
                          : "Select third row's mnemonic phase",
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 44,
                      margin: EdgeInsets.only(right: 30),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                        ),
                        color: Colors.blue,
                        disabledColor: Colors.grey,
                        iconSize: 30,
                        onPressed: currentPage > 0
                            ? () {
                                pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              }
                            : null,
                      ),
                    ),
                    Text("${currentPage + 1}/${wordPages.length}"),
                    Container(
                      width: 50,
                      height: 44,
                      margin: EdgeInsets.only(left: 30),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                        ),
                        color: Colors.blue,
                        disabledColor: Colors.grey,
                        iconSize: 30,
                        onPressed: currentPage < 2
                            ? () async {
                                await pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                margin: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width - 40,
                child: RaisedButton(
                  child: Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blue,
                  onPressed: () async {
                    setState(() {
                      this.loading = true;
                    });
                    bool isVerified = true;
                    if (bool.fromEnvironment('dart.vm.product')) {
                      isVerified = verify(mnemonics);
                    }
                    if (isVerified) {
                      Uint8List privateKey =
                          await BipKeyDerivation.decryptedByMnemonic(
                        mnemonics.join(" "),
                        defaultDerivationPath,
                      );
                      KeyStore keystore = await BipKeyDerivation.encrypt(
                          privateKey, widget.password);
                      await WalletStorage.write(
                        walletEntity: WalletEntity(
                          name: widget.walletName,
                          keystore: keystore,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isLoading: loading,
    );
  }
}

class WordPage {
  List<WaitingWord> waitingWords;
  List<RandomWord> randomWords;

  WordPage({this.waitingWords, this.randomWords});
}

class WaitingWord {
  String word;
  bool isSelected = false;
  int selectedIndex;
  int page;
  int index;
  Future<void> Function(
    int page,
    int index,
    int selectedIndex,
    String word,
    bool isSelected,
  ) action;

  WaitingWord({
    this.word,
    this.page,
    this.index,
    this.selectedIndex,
    this.action,
    this.isSelected,
  });
  Widget buildChild(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) * 0.25,
      child: RaisedButton(
        padding: EdgeInsets.all(0),
        color: Colors.green,
        disabledColor: Colors.cyan,
        onPressed: isSelected
            ? () async {
                await action(
                  this.page,
                  this.index,
                  this.selectedIndex,
                  this.word,
                  this.isSelected,
                );
              }
            : null,
        child: Text(
          this.isSelected ? this.word : '——',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class RandomWord {
  String word;
  bool isAvailable = true;
  int index;
  int page;
  Future<void> Function(
    int page,
    int index,
    String word,
    bool isAvailable,
  ) action;

  RandomWord({
    this.word,
    this.page,
    this.index,
    this.action,
    this.isAvailable,
  });

  Widget buildChild(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 70) * 0.25,
      child: RaisedButton(
        padding: EdgeInsets.all(0),
        color: Colors.blue,
        disabledColor: Colors.grey,
        onPressed: isAvailable
            ? () async {
                await action(
                    this.page, this.index, this.word, this.isAvailable);
              }
            : null,
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
