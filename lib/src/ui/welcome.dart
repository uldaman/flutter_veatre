import 'package:flutter/material.dart';
import 'package:veatre/src/ui/commonComponents.dart';
import 'package:veatre/src/ui/enterPassword.dart';
import 'package:flutter_icons/flutter_icons.dart';

class Welcome extends StatefulWidget {
  @override
  WelcomeState createState() {
    return WelcomeState();
  }
}

class WelcomeState extends State<Welcome> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 30, top: 20),
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width - 120,
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
            Padding(
              padding: EdgeInsets.only(
                top: 0,
              ),
              child: Row(
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
            ),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 60,
                child: Text(
                  'Sync is designed to provide the superior user experiences for VeChain Apps,and serves as the dApp enviroment to provide unlimited potential for developers and users.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).primaryTextTheme.display2.color,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 170,
                  height: 44,
                  child: commonButton(
                    context,
                    'Start',
                    () async {
                      await Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => new EnterPassword(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
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
