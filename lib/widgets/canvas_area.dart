import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';
import '../js_interop.dart' as js;

class CanvasArea extends StatefulWidget {
  /// Called when a click on the canvas finishes. Used to bring the side panels
  /// back while they are hidden. Dragging does not trigger it.
  final VoidCallback? onTap;

  const CanvasArea({super.key, this.onTap});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  /// Moving farther than this between press and release counts as a drag.
  static const double _tapSlop = 2;

  Offset? _pressPosition;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: (event) {
          _pressPosition = event.position;
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
          final origin = _pressPosition;
          final isTap =
              origin != null && (event.position - origin).distance <= _tapSlop;
          js.onPointerUp();
          if (isTap) {
            widget.onTap?.call();
          }
          _pressPosition = null;
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
