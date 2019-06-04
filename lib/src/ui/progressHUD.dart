import 'package:flutter/material.dart';

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
