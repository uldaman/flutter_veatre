import 'package:flutter/foundation.dart';
import 'package:veatre/common/event_bus.dart';

@immutable
class Event {
  final _name;

  const Event(this._name);

  void emit([arg]) {
    bus.emit(_name, arg);
  }

  void on(EventCallback f) {
    bus.on(_name, f);
  }
}

const onWebChanged = Event("webChanged");
const onWebViewSelected = Event("webSelected");
