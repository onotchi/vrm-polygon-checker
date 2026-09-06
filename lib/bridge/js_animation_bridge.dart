import 'dart:convert';
import 'dart:js_interop';

import 'animation_bridge.dart';
import '../js_interop.dart' as js;

/// [AnimationBridge] backed by the three.js viewer.
///
/// It also absorbs the JSON envelope the JS side answers with, so callers deal
/// in plain Dart values and never see the wire format.
class JsAnimationBridge implements AnimationBridge {
  const JsAnimationBridge();

  @override
  double getDuration() => _readNumber(js.getAnimationDuration(), 'duration');

  @override
  double getCurrentTime() => _readNumber(js.getAnimationTime(), 'time');

  @override
  bool isPaused() {
    final result = _decode(js.isAnimationPaused());
    return result['paused'] as bool? ?? false;
  }

  @override
  void seek(double seconds) => js.setAnimationTime(seconds.toJS);

  @override
  void pause() => js.pauseAnimation();

  @override
  void resume() => js.resumeAnimation();

  @override
  void stepForward() => js.stepAnimationForward();

  @override
  void stepBackward() => js.stepAnimationBackward();

  static Map<String, dynamic> _decode(JSString raw) =>
      jsonDecode(raw.toDart) as Map<String, dynamic>;

  /// The JS side answers with the value, or with an error object that still
  /// carries the same key set to zero. A missing key therefore only happens if
  /// the contract changes, and zero is the right answer for "nothing playing".
  static double _readNumber(JSString raw, String key) =>
      (_decode(raw)[key] as num?)?.toDouble() ?? 0;
}
