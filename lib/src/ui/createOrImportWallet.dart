import 'package:flutter/material.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/createWallet.dart';
import 'package:veatre/src/ui/importWallet.dart';
import 'package:flutter_icons/flutter_icons.dart';

class CreateOrImportWallet extends StatefulWidget {
  final String fromRouteName;
  CreateOrImportWallet({@required this.fromRouteName});

  @override
  CreateOrImportWalletState createState() {
    return CreateOrImportWalletState();
  }
}

class CreateOrImportWalletState extends State<CreateOrImportWallet> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 10,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 30,
                    ),
                    child: SizedBox(
                      width: 200,
                      child: Text(
                        'Get Started',
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    child: PageView(
                      physics: ClampingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      onPageChanged: (page) {
                        setState(() {
                          _page = page;
                        });
                      },
                      children: <Widget>[
                        Image.asset(
                          'assets/step1.png',
                          fit: BoxFit.fitHeight,
                        ),
                        Image.asset(
                          'assets/step2.png',
                          fit: BoxFit.fitHeight,
                        ),
                        Image.asset(
                          'assets/step3.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Container(
                          width: 150,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              _pageDot(context, 0),
                              _pageDot(context, 1),
                              _pageDot(context, 2),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 44,
                    child: commonButton(
                      context,
                      'Create a new wallet',
                      () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateWallet(
                              rootRouteName: widget.fromRouteName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 60,
                      height: 44,
                      child: commonButton(
                        context,
                        'Import existed wallet',
                        () async {
                          await Navigator.push(
                            context,
                            new MaterialPageRoute(
                              builder: (context) => new ImportWallet(
                                rootRouteName: widget.fromRouteName,
                              ),
                            ),
                          );
                        },
                        color: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageDot(BuildContext context, int page) {
    return Icon(
      MaterialCommunityIcons.checkbox_blank_circle,
      size: 15,
      color: _page == page
          ? Theme.of(context).primaryTextTheme.title.color
          : Theme.of(context).primaryTextTheme.display3.color,
    );
  }
}
