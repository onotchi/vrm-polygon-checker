import 'package:flutter/foundation.dart';

/// The browser's fullscreen state, as far as the app is concerned.
///
/// A plain Dart interface so the button that uses it can be built in a widget
/// test. The browser-backed implementation is in `js_fullscreen_bridge.dart`.
abstract interface class FullscreenBridge {
  /// Whether the page is currently displayed fullscreen.
  bool isFullscreen();

  /// Enters fullscreen, or leaves it if already there. Browsers only honour
  /// this from a user gesture.
  void toggle();

  /// Registers [listener] for fullscreen changes, including ones the app did
  /// not initiate -- Esc, F11, or the browser's own control.
  ///
  /// Returns the function that unregisters it again.
  VoidCallback onChange(VoidCallback listener);
}
