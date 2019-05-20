import 'package:flutter/material.dart';
import 'package:vetheat/common/event_bus.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController editingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        elevation: 2.0,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10.0),
          child: TextField(
            maxLines: 1,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(bottom: 6.0, top: 8.0),
              hintText: "Url | app | block | tx | account",
              border: InputBorder.none,
            ),
            onSubmitted: onSubmitted,
            controller: editingController,
          ),
        ),
      ),
    );
  }

  onSubmitted(String url) {
    bus.emit("goUrl", url);
  }
}
