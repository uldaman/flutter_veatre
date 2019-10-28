import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class _SwipeValue {
  bool enabled;
  bool rollBack;
  bool shouldLoading;

  _SwipeValue({
    bool enabled,
    bool rollBack,
    bool shouldLoading,
  }) {
    this.enabled = enabled ?? true;
    this.rollBack = rollBack ?? false;
    this.shouldLoading = shouldLoading ?? false;
  }
}

class SwipeController extends ValueNotifier<_SwipeValue> {
  SwipeController({_SwipeValue value}) : super(value ?? _SwipeValue());

  valueWith({
    bool enabled,
    bool rollBack,
    bool shouldLoading,
  }) {
    this.value = _SwipeValue(
      enabled: enabled ?? this.value.enabled,
      rollBack: rollBack ?? this.value.rollBack,
      shouldLoading: shouldLoading ?? this.value.shouldLoading,
    );
  }
}

class SwipeButton extends StatefulWidget {
  const SwipeButton({
    Key key,
    this.content,
    BorderRadius borderRadius,
    this.swipeController,
    this.height = 56.0,
    @required this.onDragEnd,
  })  : assert(onDragEnd != null && height != null),
        this.borderRadius = borderRadius ?? BorderRadius.zero,
        super(key: key);

  final Widget content;
  final BorderRadius borderRadius;
  final double height;
  final SwipeController swipeController;
  final Function onDragEnd;

  @override
  SwipeButtonState createState() => SwipeButtonState();
}

class SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _positionedKey = GlobalKey();
  AnimationController _controller;
  Offset _start = Offset.zero;
  bool enabled = true;
  bool shouldLoading = false;

  RenderBox get _positioned => _positionedKey.currentContext.findRenderObject();
  RenderBox get _container => _containerKey.currentContext.findRenderObject();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _handleValueChanged();
    widget.swipeController.addListener(_handleValueChanged);
  }

  void _handleValueChanged() async {
    setState(() {
      enabled = widget.swipeController.value.enabled;
      shouldLoading = widget.swipeController.value.shouldLoading;
    });
    if (widget.swipeController.value.rollBack) {
      final simulation = _SwipeSimulation(-2, _controller.value, 0, -4);
      await _controller.animateWith(simulation);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.swipeController.removeListener(_handleValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: <Widget>[
              DecoratedBox(
                key: _containerKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0, -4.0),
                    end: Alignment(1.0, 4.0),
                    colors: [const Color(0xFF81269D), const Color(0xFFEE112D)],
                    stops: [0, 1],
                  ),
                  boxShadow: [
                    // BoxShadow(
                    //   blurRadius: 2,
                    //   color: Colors.lightBlue,
                    //   offset: Offset(2, 2),
                    // )
                  ],
                  borderRadius: widget.borderRadius,
                ),
                child: ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  clipper: _SwipeButtonClipper(
                    minimalWidth: widget.height,
                    animation: _controller,
                    borderRadius: widget.borderRadius,
                  ),
                  borderRadius: widget.borderRadius,
                  child: SizedBox.expand(
                    child: Container(
                      color: Colors.blueGrey,
                      child: widget.content,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment((_controller.value * 2.0) - 1.0, 0.0),
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    key: _positionedKey,
                    width: widget.height,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: enabled ? Colors.green[300] : Colors.grey[400],
                      borderRadius: widget.borderRadius,
                    ),
                    child: Stack(
                      children: <Widget>[
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.blueAccent),
                            value: _controller.value,
                            strokeWidth: 2,
                          ),
                        ),
                        shouldLoading
                            ? SizedBox.expand(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.blueAccent,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : SizedBox.expand(
                                child: CustomPaint(
                                  painter: _DrawCheck(
                                    backgroundColor: Colors.brown,
                                    strokeColor: Colors.white,
                                    progress: _controller.value,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (enabled) {
      final pos = _positioned.globalToLocal(details.globalPosition);
      _start = Offset(pos.dx, 0.0);
      _controller.stop(canceled: true);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (enabled) {
      final pos = _container.globalToLocal(details.globalPosition) - _start;
      final extent = _container.size.width - _positioned.size.width;
      _controller.value = (pos.dx.clamp(0.0, extent) / extent);
    }
  }

  void _onDragEnd(DragEndDetails details) async {
    if (enabled) {
      final extent = _container.size.width - _positioned.size.width;
      double fractionalVelocity = (details.primaryVelocity / extent).abs();
      if (fractionalVelocity < 1) {
        fractionalVelocity = 1;
      }
      double acceleration, velocity;
      if (_controller.value < 1) {
        acceleration = -2;
        velocity = -fractionalVelocity;
      } else {
        acceleration = 2;
        velocity = fractionalVelocity;
      }
      final simulation = _SwipeSimulation(
        acceleration,
        _controller.value,
        1.0,
        velocity,
      );
      await _controller.animateWith(simulation);
      if (_controller.value == 1.0) {
        await widget.onDragEnd();
      }
    }
  }
}

class _SwipeSimulation extends GravitySimulation {
  _SwipeSimulation(
      double acceleration, double distance, double endDistance, double velocity)
      : super(acceleration, distance, endDistance, velocity);

  @override
  double x(double time) => super.x(time).clamp(0.0, 1.0);

  @override
  bool isDone(double time) {
    final _x = x(time).abs();
    return (_x <= 0.0) || (_x >= 1.0 && time != 0);
  }
}

class _SwipeButtonClipper extends CustomClipper<RRect> {
  const _SwipeButtonClipper({
    @required this.minimalWidth,
    @required this.animation,
    @required this.borderRadius,
  })  : assert(animation != null && borderRadius != null),
        super(reclip: animation);

  final Animation<double> animation;
  final BorderRadius borderRadius;
  final double minimalWidth;

  @override
  RRect getClip(Size size) {
    return borderRadius.toRRect(
      Rect.fromLTRB(
        (size.width - minimalWidth) * animation.value,
        0.0,
        size.width,
        size.height,
      ),
    );
  }

  @override
  bool shouldReclip(_SwipeButtonClipper oldClipper) => true;
}

class _DrawCheck extends CustomPainter {
  Color backgroundColor;
  Color strokeColor;
  double progress;
  double strokeWidth;

  _DrawCheck({
    this.strokeColor = Colors.white,
    this.backgroundColor = Colors.grey,
    this.progress = 0,
    this.strokeWidth = 2,
  }) : assert(progress != null);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = backgroundColor;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = strokeWidth;
    final minOffset = min(size.width, size.height);
    Point p1 =
        Point(size.width / 2 - minOffset / 5, size.height / 2 + minOffset / 20);
    Point p2 =
        Point(size.width / 2 - minOffset / 20, size.height / 2 + minOffset / 8);
    Point p3 =
        Point(size.width / 2 + minOffset / 8, size.height / 2 - minOffset / 8);
    canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
    canvas.drawLine(Offset(p2.x, p2.y), Offset(p3.x, p3.y), paint);
    paint.color = strokeColor;
    if (progress <= 0.3) {
      double nmd = progress / 0.3;
      canvas.drawLine(
        Offset(
          p1.x,
          p1.y,
        ),
        Offset(
          nmd * p2.x + (1 - nmd) * p1.x,
          nmd * p2.y + (1 - nmd) * p1.y,
        ),
        paint,
      );
    } else {
      double nmd = (progress - 0.3) / 0.7;
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
      canvas.drawLine(
        Offset(
          p2.x,
          p2.y,
        ),
        Offset(
          nmd * p3.x + (1 - nmd) * p2.x,
          nmd * p3.y + (1 - nmd) * p2.y,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DrawCheck oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_DrawCheck oldDelegate) => false;
}
