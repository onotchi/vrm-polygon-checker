import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';
import '../js_interop.dart' as js;

class CanvasArea extends StatelessWidget {
  const CanvasArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: (event) {
          js.onPointerDown(
            event.position.dx.toJS,
            event.position.dy.toJS,
            event.buttons.toJS,
          );
        },
        onPointerMove: (event) {
          js.onPointerMove(
            event.position.dx.toJS,
            event.position.dy.toJS,
          );
        },
        onPointerUp: (event) {
          js.onPointerUp();
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            js.onWheel(event.scrollDelta.dy.toJS);
          }
        },
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
