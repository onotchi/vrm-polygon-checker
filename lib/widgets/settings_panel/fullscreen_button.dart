import 'package:flutter/material.dart';
import '../../bridge/fullscreen_bridge.dart';
import '../../localization.dart';

/// Fullscreen toggle. Keeps its own state so it stays in sync when the user
/// leaves fullscreen by pressing Esc or the browser's own shortcut.
///
/// Note for later: do not make the call site `const`. A const widget is the
/// same instance on every rebuild, so Flutter skips rebuilding it and the label
/// would keep the wording of whichever language was loaded first.
class FullscreenButton extends StatefulWidget {
  const FullscreenButton({super.key, required this.bridge});

  final FullscreenBridge bridge;

  @override
  State<FullscreenButton> createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<FullscreenButton> {
  bool _isFullscreen = false;
  VoidCallback? _stopListening;

  @override
  void initState() {
    super.initState();
    _stopListening = widget.bridge.onChange(_syncState);
    _syncState();
  }

  @override
  void dispose() {
    _stopListening?.call();
    super.dispose();
  }

  void _syncState() {
    final value = widget.bridge.isFullscreen();
    if (value != _isFullscreen) {
      setState(() => _isFullscreen = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          widget.bridge.toggle();
          _syncState();
        },
        icon: Icon(
          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          size: 18,
        ),
        label: Text(
          Localization.get(_isFullscreen ? 'exitFullscreen' : 'fullscreen'),
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
