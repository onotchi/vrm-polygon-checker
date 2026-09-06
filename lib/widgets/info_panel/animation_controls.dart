import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../../localization.dart';
import '../../js_interop.dart' as js;

/// The loaded animation: its file name, a stop button, and the seek bar with
/// playback controls.
///
/// Unlike the other panel sections this one does call into JS directly. The
/// seek bar polls the playhead on a 50ms timer, which is state belonging to the
/// widget itself -- hoisting it into the parent would put a Timer in main.dart
/// for no gain. Keeping it here means every playback call lives in this file.
class AnimationControls extends StatelessWidget {
  const AnimationControls({
    super.key,
    required this.animationInfo,
    required this.onStop,
  });

  final Map<String, dynamic> animationInfo;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        animationInfo['fileName'] ?? 'Animation',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: onStop,
                      icon: const Icon(Icons.stop),
                      tooltip: Localization.get('stopAnimation'),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                // Each load hands over a fresh map, so keying on it rebuilds
                // the seek bar for the new clip. Without a key the state is
                // reused and keeps showing the previous clip's duration.
                _AnimationSeekBar(key: ValueKey(animationInfo)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Animation seek bar widget with periodic updates
class _AnimationSeekBar extends StatefulWidget {
  const _AnimationSeekBar({super.key});

  @override
  State<_AnimationSeekBar> createState() => _AnimationSeekBarState();
}

class _AnimationSeekBarState extends State<_AnimationSeekBar> {
  Timer? _timer;
  double _currentTime = 0;
  double _duration = 0;
  bool _isDragging = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _fetchDuration();
    _fetchPausedState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchDuration() {
    final result = jsonDecode(js.getAnimationDuration().toDart);
    if (result['duration'] != null) {
      setState(() {
        _duration = (result['duration'] as num).toDouble();
      });
    }
  }

  void _fetchPausedState() {
    final result = jsonDecode(js.isAnimationPaused().toDart);
    if (result['paused'] != null) {
      setState(() {
        _isPaused = result['paused'] as bool;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isDragging) {
        final result = jsonDecode(js.getAnimationTime().toDart);
        if (result['time'] != null) {
          setState(() {
            _currentTime = (result['time'] as num).toDouble();
          });
        }
      }
    });
  }

  void _togglePlayPause() {
    if (_isPaused) {
      js.resumeAnimation();
    } else {
      js.pauseAnimation();
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stepForward() {
    js.stepAnimationForward();
    setState(() {
      _isPaused = true;
    });
  }

  void _stepBackward() {
    js.stepAnimationBackward();
    setState(() {
      _isPaused = true;
    });
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).toStringAsFixed(1);
    return '$mins:${secs.padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_duration <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: _currentTime.clamp(0, _duration),
            min: 0,
            max: _duration,
            onChangeStart: (_) {
              _isDragging = true;
            },
            onChanged: (value) {
              setState(() {
                _currentTime = value;
              });
            },
            onChangeEnd: (value) {
              js.setAnimationTime(value.toJS);
              _isDragging = false;
            },
          ),
        ),
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _stepBackward,
              icon: const Icon(Icons.skip_previous),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: Localization.get('previousFrame'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: Localization.get(_isPaused ? 'play' : 'pause'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _stepForward,
              icon: const Icon(Icons.skip_next),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: Localization.get('nextFrame'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_currentTime),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                _formatTime(_duration),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
