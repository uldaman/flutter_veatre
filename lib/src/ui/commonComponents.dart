import 'package:flutter/material.dart';
import 'package:veatre/src/utils/mersenneTwister.dart';
import 'package:flutter_icons/flutter_icons.dart';

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
          padding: EdgeInsets.symmetric(vertical: 15),
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
          height: 1,
        ),
      ],
    ),
    onTap: onPressed,
  );
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

TextField walletNameTextField({
  TextEditingController controller,
  String hitText,
  String errorText,
  FocusNode focusNode,
}) {
  return TextField(
    controller: controller,
    maxLength: 10,
    autofocus: true,
    focusNode: focusNode,
    decoration: InputDecoration(
      hintText: hitText,
      errorText: errorText,
    ),
  );
}

class PassClearController extends ValueNotifier<bool> {
  PassClearController({bool shouldClear = true}) : super(shouldClear);

  void clear() {
    this.value = !this.value;
  }
}

class Passcodes extends StatefulWidget {
  final int maxLength;
  final ValueChanged<String> onChanged;
  final double paddingLeft;
  final double paddingRight;
  final PassClearController controller;

  Passcodes({
    Key key,
    @required this.onChanged,
    this.maxLength,
    this.paddingLeft,
    this.paddingRight,
    this.controller,
  }) : super(key: key);

  @override
  _PasscodesState createState() => _PasscodesState();
}

class _PasscodesState extends State<Passcodes> {
  int _maxLength;
  double _paddingLeft;
  double _paddingRight;
  FocusNode _focusNode = FocusNode(canRequestFocus: true);
  TextEditingController _controller = TextEditingController();
  List<String> _passcodes = [];

  @override
  void initState() {
    _maxLength = widget.maxLength ?? 6;
    _paddingLeft = widget.paddingLeft ?? 30;
    _paddingRight = widget.paddingRight ?? 30;
    if (widget.controller != null) {
      widget.controller.addListener(_handlePassClear);
    }
    super.initState();
  }

  _handlePassClear() {
    if (widget.controller != null) {
      setState(() {
        _controller.clear();
        _passcodes = [];
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller.removeListener(_handlePassClear);
    }
    _focusNode.unfocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        buildPasscodes(
          context,
          _passcodes,
        ),
        SizedBox(
          height:
              (MediaQuery.of(context).size.width - 5 * 10 - 40) / _maxLength,
          width: (MediaQuery.of(context).size.width -
              _paddingLeft -
              _paddingRight),
          child: EditableText(
            cursorWidth: 0,
            cursorColor: Colors.transparent,
            backgroundCursorColor: Colors.transparent,
            focusNode: _focusNode,
            autofocus: true,
            controller: _controller,
            style: TextStyle(color: Colors.transparent),
            keyboardType: TextInputType.number,
            maxLines: 1,
            obscureText: true,
            onChanged: (text) {
              if (text.length > _maxLength) {
                _controller.text = text.substring(0, _maxLength);
              }
              setState(() {
                _passcodes = _controller.text.split('');
              });
              widget.onChanged(_controller.text);
            },
          ),
        ),
      ],
    );
  }

  Widget buildPasscodes(
    BuildContext context,
    List<String> passcodes, {
    double paddingLeft = 30,
    double paddingRight = 30,
  }) {
    List<Widget> passcodeWidgets = [];
    for (int i = 0; i < _maxLength; i++) {
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
      width: (MediaQuery.of(context).size.width - 5 * 10 - 40) / _maxLength,
      height: (MediaQuery.of(context).size.width - 5 * 10 - 40) / _maxLength,
      child: Card(
        elevation: 0,
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
                  MaterialCommunityIcons.checkbox_blank_circle,
                  size: 17,
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              )
            : SizedBox(),
      ),
    );
  }
}
