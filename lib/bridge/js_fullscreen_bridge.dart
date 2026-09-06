import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'fullscreen_bridge.dart';
import '../js_interop.dart' as js;

/// [FullscreenBridge] backed by the browser.
class JsFullscreenBridge implements FullscreenBridge {
  const JsFullscreenBridge();

  @override
  bool isFullscreen() {
    final result = jsonDecode(js.isFullscreen().toDart) as Map<String, dynamic>;
    return result['fullscreen'] == true;
  }

  @override
  void toggle() => js.toggleFullscreen();

  @override
  VoidCallback onChange(VoidCallback listener) {
    final jsListener = ((web.Event event) => listener()).toJS;
    // Both names are registered: WebKit fires only the prefixed one.
    web.document.addEventListener('fullscreenchange', jsListener);
    web.document.addEventListener('webkitfullscreenchange', jsListener);

    return () {
      web.document.removeEventListener('fullscreenchange', jsListener);
      web.document.removeEventListener('webkitfullscreenchange', jsListener);
    };
  }
}
