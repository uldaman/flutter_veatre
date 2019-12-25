import 'package:flutter/material.dart';
import 'package:veatre/src/utils/mersenneTwister.dart';

class Picasso extends StatelessWidget {
  final String content;
  final double size;
  final double borderRadius;

  Picasso(this.content, {this.size = 60, this.borderRadius = 10, Key key})
      : super(key: key);

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
          opacity: 0.9,
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
