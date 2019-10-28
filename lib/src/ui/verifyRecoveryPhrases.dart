import 'package:flutter/material.dart';
import 'package:veatre/src/utils/common.dart';
import 'package:veatre/src/storage/walletStorage.dart';

class VerifyRecoveryPhrase extends StatefulWidget {
  final String mnemonic;
  final String rootRouteName;

  VerifyRecoveryPhrase({
    Key key,
    @required this.mnemonic,
    @required this.rootRouteName,
  }) : super(key: key);

  _VerifyRecoveryPhraseState createState() => _VerifyRecoveryPhraseState();
}

class _VerifyRecoveryPhraseState extends State<VerifyRecoveryPhrase> {
  List<IdleWord> idleWords;
  List<RandomWord> randomWords;
  String errorMsg;

  @override
  void initState() {
    super.initState();
    List<String> randoms = widget.mnemonic.split(' ');
    randoms.shuffle();
    randomWords = List(randoms.length);
    idleWords = List(randoms.length);
    for (int i = 0; i < idleWords.length; i++) {
      idleWords[i] = IdleWord(
        isMarked: false,
      );
      randomWords[i] = RandomWord(
        word: randoms[i],
        isSelected: false,
      );
    }
  }

  Widget buildIdleWord(int index) {
    IdleWord idleWord = idleWords[index];
    if (!idleWord.isMarked) {
      return Align(
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 17,
          ),
        ),
      );
    }
    return FlatButton(
      child: Text(
        '${idleWord.word}',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        side: BorderSide(
          color: Theme.of(context).textTheme.title.color,
          width: 0,
        ),
      ),
      onPressed: () async {
        setState(() {
          randomWords[idleWord.originIndex].isSelected = false;
          idleWords[index].clear();
          errorMsg = null;
        });
      },
    );
  }

  Widget buildRandomWord(int index) {
    RandomWord randomWord = randomWords[index];
    if (!randomWord.isSelected) {
      return FlatButton(
        child: Text(
          '${randomWord.word}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          side: BorderSide(
            color: Theme.of(context).textTheme.title.color,
            width: 0,
          ),
        ),
        onPressed: () async {
          setState(() {
            randomWords[index].isSelected = true;
            for (IdleWord idleWord in idleWords) {
              if (!idleWord.isMarked) {
                idleWord.word = randomWord.word;
                idleWord.originIndex = index;
                idleWord.isMarked = true;
                break;
              }
            }
            errorMsg = null;
          });
        },
      );
    }
    return Align(
      alignment: Alignment.center,
      child: Text(
        '${randomWord.word}',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Verify Recovery Phrases'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                color: Colors.grey[250],
                height: 20,
              ),
              Container(
                height: 200,
                color: Theme.of(context).primaryColor,
                child: GridView.builder(
                  padding: EdgeInsets.all(10),
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 4,
                  ),
                  itemCount: idleWords.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      child: buildIdleWord(index),
                    );
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[250],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Text(
                            'Select the phrase in correct order',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 220,
                        child: GridView.builder(
                          padding: EdgeInsets.all(10),
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 3.5,
                          ),
                          itemCount: randomWords.length,
                          itemBuilder: (context, index) {
                            return buildRandomWord(index);
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 60,
                        height: 24,
                        child: errorMsg != null
                            ? Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Text(
                                      errorMsg,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 60,
                height: 44,
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    side: BorderSide(
                      color: Theme.of(context).textTheme.title.color,
                      width: 0,
                    ),
                  ),
                  color: Theme.of(context).textTheme.title.color,
                  child: Text(
                    "Verify",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20,
                    ),
                  ),
                  disabledColor: Colors.grey[500],
                  onPressed: hasFilled
                      ? () async {
                          if (verify()) {
                            String address = await addressFrom(widget.mnemonic);
                            await WalletStorage.updateHasBackup(address, true);
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName(widget.rootRouteName),
                            );
                          } else {
                            setState(() {
                              errorMsg =
                                  'Incorrect recovery phrases, please double check.';
                            });
                          }
                        }
                      : null,
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ));
  }

  bool get hasFilled {
    for (IdleWord idleWord in idleWords) {
      if (!idleWord.isMarked) {
        return false;
      }
    }
    return true;
  }

  bool verify() {
    List<String> idles = [];
    for (IdleWord idleWord in idleWords) {
      idles.add(idleWord.word);
    }
    return idles.join(" ") == widget.mnemonic;
  }

  TextField textField({
    TextEditingController controller,
    String hitText,
    String errorText,
  }) {
    return TextField(
      controller: controller,
      maxLength: 20,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hitText,
        errorText: errorText,
      ),
      style: Theme.of(context).textTheme.body1,
    );
  }
}

class IdleWord {
  int originIndex;
  String word;
  bool isMarked = false;

  IdleWord({
    this.originIndex,
    this.word,
    this.isMarked,
  });

  void clear() {
    this.originIndex = null;
    this.word = null;
    this.isMarked = false;
  }
}

class RandomWord {
  final String word;
  bool isSelected = false;

  RandomWord({
    this.word,
    this.isSelected,
  });
}
