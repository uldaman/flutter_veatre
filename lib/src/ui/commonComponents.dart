import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:veatre/src/utils/mersenneTwister.dart';

Future alert(BuildContext context, Widget title, String message) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: Theme.of(context).cardTheme.shape,
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
        title: title == null
            ? null
            : Align(
                alignment: Alignment.bottomCenter,
                child: title,
              ),
        content: Wrap(
          children: <Widget>[
            Text(
              message,
              style: TextStyle(color: Theme.of(context).textTheme.title.color),
            ),
          ],
        ),
      );
    },
  );
}

Future customAlert(
  BuildContext context, {
  Widget title,
  Widget content,
  Future<void> Function() confirmAction,
  Future<void> Function() cancelAction,
}) async {
  void Function() defauctAction = () {};
  Future<void> Function() cancel = cancelAction ?? defauctAction;
  Future<void> Function() ok = confirmAction ?? defauctAction;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).backgroundColor,
        contentPadding:
            EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
        shape: Theme.of(context).cardTheme.shape,
        title: title == null
            ? null
            : Align(
                alignment: Alignment.bottomCenter,
                child: title,
              ),
        content: Wrap(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.center,
                child: content,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () async {
                    await ok();
                  },
                ),
                FlatButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFEF6F6F)),
                  ),
                  onPressed: () async {
                    await cancel();
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}

Widget commonButton(
  BuildContext context,
  String title,
  Function onPressed, {
  Color color,
  Color textColor,
  Color disabledColor,
}) {
  return FlatButton(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      side: BorderSide.none,
    ),
    color: color ?? Theme.of(context).primaryColor,
    child: Text(
      title,
      style: TextStyle(
        color: textColor ?? Theme.of(context).accentColor,
        fontSize: 17,
      ),
    ),
    disabledColor:
        disabledColor ?? Theme.of(context).primaryTextTheme.display3.color,
    onPressed: onPressed,
  );
}

Widget cell(
  BuildContext context,
  String title,
  Widget right, {
  bool showIcon = false,
  Function() onPressed,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    child: Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 100,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).primaryTextTheme.display2.color,
                    fontSize: 17,
                  ),
                ),
              ),
              Expanded(
                child: right,
              ),
              SizedBox(
                width: 44,
                child: showIcon
                    ? Icon(
                        Icons.arrow_forward_ios,
                        size: 17,
                      )
                    : SizedBox(),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1,
        ),
      ],
    ),
    onTap: onPressed,
  );
}

Widget buildPasscodes(
  BuildContext context,
  List<String> passcodes,
  int maxLength, {
  double paddingLeft = 30,
  double paddingRight = 30,
}) {
  List<Widget> passcodeWidgets = [];
  for (int i = 0; i < maxLength; i++) {
    passcodeWidgets.add(_passcode(context, passcodes, i));
  }
  return Padding(
    padding: EdgeInsets.only(
      left: paddingLeft,
      right: paddingRight,
    ),
    child: Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: passcodeWidgets,
      ),
    ),
  );
}

Widget _passcode(BuildContext context, List<String> passcodes, index) {
  return Container(
    width: (MediaQuery.of(context).size.width - 5 * 10 - 40) / 6,
    height: (MediaQuery.of(context).size.width - 5 * 10 - 40) / 6,
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        side: BorderSide(
          color: Theme.of(context).primaryTextTheme.display3.color,
          width: 1,
        ),
      ),
      child: index < passcodes.length
          ? Align(
              alignment: Alignment.center,
              child: Icon(
                FontAwesomeIcons.solidCircle,
                size: 17,
                color: Theme.of(context).primaryTextTheme.title.color,
              ),
            )
          : SizedBox(),
    ),
  );
}

Widget passcodeKeyboard(
  BuildContext context, {
  Future<void> Function(String code) onCodeSelected,
  Future<void> Function() onDelete,
}) {
  return Container(
    height: 280,
    // color: Color(0xFFCCCCCC),
    child: GridView.builder(
      padding: EdgeInsets.all(10),
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index < 9) {
          return codeButton(context, '${index + 1}', onCodeSelected);
        } else if (index == 9) {
          return SizedBox(
            height: 56,
          );
        } else if (index == 10) {
          return codeButton(context, "0", onCodeSelected);
        }
        return SizedBox(
          height: 56,
          child: IconButton(
            color: Colors.green,
            icon: Icon(
              Icons.backspace,
              size: 30,
              color: Colors.grey[500],
            ),
            onPressed: onDelete,
          ),
        );
      },
    ),
  );
}

Widget codeButton(
  BuildContext context,
  String code,
  Future<void> Function(String code) onCodeSelected,
) {
  return SizedBox(
    width: (MediaQuery.of(context).size.width - 40) / 3,
    height: 56,
    child: CodeButton(
      code: code,
      onCodeSelected: onCodeSelected,
    ),
  );
}

typedef onCodeSelectedCallback = Future<void> Function(String code);

class CodeButton extends StatelessWidget {
  final String code;
  final onCodeSelectedCallback onCodeSelected;

  CodeButton({@required this.code, @required this.onCodeSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: FlatButton(
          child: Text(
            code,
            style: TextStyle(
              color: Theme.of(context).textTheme.title.color,
              fontSize: 25,
            ),
          ),
          onPressed: () async {
            await onCodeSelected(code);
          },
        ),
      ),
    );
  }
}

class ProgressHUD extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  ProgressHUD({this.isLoading, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: isLoading
          ? [
              child,
              Opacity(
                opacity: 0.3,
                child:
                    const ModalBarrier(dismissible: false, color: Colors.grey),
              ),
              Center(
                child: new CircularProgressIndicator(),
              ),
            ]
          : [
              child,
            ],
    );
  }
}

class Picasso extends StatelessWidget {
  final String content;
  final double size;
  final double borderRadius;

  Picasso(this.content, {this.size = 60, this.borderRadius = 10});

  @override
  Widget build(BuildContext context) {
    List<double> rs = [
      0.35,
      0.40,
      0.45,
      0.50,
      0.55,
      0.60,
    ];
    List<double> cxs = [
      0,
      0.10,
      0.20,
      0.30,
      0.40,
      0.50,
      0.60,
      0.70,
      0.80,
      0.90,
      1.0
    ];
    List<double> cys = [
      0.30,
      0.40,
      0.50,
      0.60,
      0.70,
    ];
    List<Color> colors = [
      Color.fromRGBO(226, 27, 12, 1),
      Color.fromRGBO(192, 19, 78, 1),
      Color.fromRGBO(125, 31, 141, 1),
      Color.fromRGBO(82, 46, 146, 1),
      Color.fromRGBO(50, 65, 145, 1),
      Color.fromRGBO(11, 122, 209, 1),
      Color.fromRGBO(2, 135, 195, 1),
      Color.fromRGBO(0, 150, 170, 1),
      Color.fromRGBO(0, 120, 109, 1),
      Color.fromRGBO(61, 140, 64, 1),
      Color.fromRGBO(112, 162, 54, 1),
      Color.fromRGBO(174, 188, 33, 1),
      Color.fromRGBO(210, 157, 0, 1),
      Color.fromRGBO(204, 122, 0, 1),
      Color.fromRGBO(231, 55, 0, 1),
    ];
    final rand = MersenneTwister(hash(content));
    final genColor = () {
      final idx = (colors.length * rand.nextDouble()).floor();
      return colors.removeAt(idx);
    };
    final backGroundColor = genColor();
    List<Widget> circles = [];
    for (int i = 0; i < 3; i++) {
      final r = rs.removeAt((rs.length * rand.nextDouble()).floor());
      final cx = cxs.removeAt((cxs.length * rand.nextDouble()).floor());
      final cy = cys.removeAt((cys.length * rand.nextDouble()).floor());
      Color color = genColor();
      circles.add(
        Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _DrawCircle(
                ratioX: cx,
                ratioY: cy,
                radius: r,
                color: color,
              ),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: new BorderRadius.all(new Radius.circular(borderRadius)),
      child: Container(
        color: backGroundColor,
        width: size,
        height: size,
        child: Stack(
          children: circles,
        ),
      ),
    );
  }

  int hash(String str) {
    if (str.length == 0) {
      return 0;
    }
    int h = 0;
    for (int i = 0; i < str.length; i++) {
      h = h * 31 + str.codeUnitAt(i);
      h = h % (1 << 32);
    }
    return h;
  }
}

class _DrawCircle extends CustomPainter {
  final Color color;
  final double ratioX;
  final double ratioY;
  final double radius;

  _DrawCircle({
    this.ratioX = 0,
    this.ratioY = 0,
    this.color = Colors.white,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * ratioX, size.height * ratioY),
        radius * size.width, paint);
  }

  @override
  bool shouldRepaint(_DrawCircle oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_DrawCircle oldDelegate) => false;
}
