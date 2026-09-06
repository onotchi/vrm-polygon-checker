/// Playback control over the animation running in the 3D viewer.
///
/// This is a plain Dart interface on purpose: widgets depend on it rather than
/// on the JS layer, so they compile and run under `flutter test` on the VM,
/// where `dart:js_interop` conversions do not exist. The JS-backed
/// implementation lives in `js_animation_bridge.dart` and is wired in from
/// main.dart, which is the only place that needs to know about it.
abstract interface class AnimationBridge {
  /// Length of the loaded clip in seconds, or 0 when nothing is playing.
  double getDuration();

  /// Current playhead position in seconds, or 0 when nothing is playing.
  double getCurrentTime();

  /// Whether playback is currently paused.
  bool isPaused();

  /// Moves the playhead to [seconds].
  void seek(double seconds);

  void pause();

  void resume();

  /// Advances one frame and pauses.
  void stepForward();

  /// Rewinds one frame and pauses.
  void stepBackward();
}
