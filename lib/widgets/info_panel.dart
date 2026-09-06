import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:js_interop';
import '../localization.dart';
import '../js_interop.dart' as js;
import 'info_panel/mesh_inspector.dart';

class InfoPanel extends StatelessWidget {
  final double width;
  final Map<String, dynamic>? vrmInfo;
  final Map<String, dynamic>? animationInfo;
  final bool isLoading;
  final bool isLoadingAnimation;
  final String? errorMessage;
  final String? activeExpression;
  final String? focusedMesh;
  final Set<String> wireframeMeshes;
  final Set<String> hiddenMeshes;
  final String meshSortKey;
  final bool meshSortAscending;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenAnimation;
  final VoidCallback onStopAnimation;
  final ValueChanged<String?> onExpressionChanged;
  final ValueChanged<String> onMeshVisibilityChanged;
  final ValueChanged<String> onMeshFocusChanged;
  final ValueChanged<String> onMeshWireframeChanged;
  final ValueChanged<String> onMeshHighlight;
  final VoidCallback onShowAllMeshes;
  final VoidCallback onHideAllMeshes;
  final VoidCallback onWireframeAllMeshes;
  final VoidCallback onClearAllWireframes;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onSortReset;
  final ValueChanged<double> onWidthChanged;

  const InfoPanel({
    super.key,
    required this.width,
    required this.vrmInfo,
    required this.animationInfo,
    required this.isLoading,
    required this.isLoadingAnimation,
    required this.errorMessage,
    required this.activeExpression,
    required this.focusedMesh,
    required this.wireframeMeshes,
    required this.hiddenMeshes,
    required this.meshSortKey,
    required this.meshSortAscending,
    required this.onOpenFile,
    required this.onOpenAnimation,
    required this.onStopAnimation,
    required this.onExpressionChanged,
    required this.onMeshVisibilityChanged,
    required this.onMeshFocusChanged,
    required this.onMeshWireframeChanged,
    required this.onMeshHighlight,
    required this.onShowAllMeshes,
    required this.onHideAllMeshes,
    required this.onWireframeAllMeshes,
    required this.onClearAllWireframes,
    required this.onSortChanged,
    required this.onSortReset,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Resize handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final newWidth = width - details.delta.dx;
              onWidthChanged(newWidth.clamp(250, 600));
            },
            child: Container(
              width: 4,
              color: Colors.grey.shade300,
            ),
          ),
        ),
        // Panel content
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: const Text(
                    'VRM Polygon Checker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildButtons(context),
                        if (animationInfo != null) _buildAnimationCard(context),
                        const SizedBox(height: 24),
                        _buildVrmInfoSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onOpenFile,
            icon: const Icon(Icons.folder_open),
            label: Text(Localization.get('openVrmFile')),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoadingAnimation ? null : onOpenAnimation,
            icon: const Icon(Icons.animation),
            label: Text(Localization.get('loadAnimation')),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationCard(BuildContext context) {
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
                        animationInfo!['fileName'] ?? 'Animation',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      onPressed: onStopAnimation,
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

  Widget _buildVrmInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localization.get('vrmInfo'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (errorMessage != null)
          Text(errorMessage!, style: const TextStyle(color: Colors.red))
        else if (vrmInfo != null)
          _buildInfoTable(context)
        else
          Text(Localization.get('noVrmLoaded')),
      ],
    );
  }

  Widget _buildInfoTable(BuildContext context) {
    final fileName = vrmInfo!['fileName'] as String?;
    final meshDetails = vrmInfo!['meshDetails'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileName != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VRM ${vrmInfo!['vrmVersion'] ?? '?'}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _buildBasicInfo(context),
        if (meshDetails != null && meshDetails.isNotEmpty) ...[
          const Divider(),
          MeshInspector(
            meshDetails: meshDetails,
            hiddenMeshes: hiddenMeshes,
            wireframeMeshes: wireframeMeshes,
            focusedMesh: focusedMesh,
            sortKey: meshSortKey,
            sortAscending: meshSortAscending,
            onSortChanged: onSortChanged,
            onSortReset: onSortReset,
            onVisibilityChanged: onMeshVisibilityChanged,
            onFocusChanged: onMeshFocusChanged,
            onWireframeChanged: onMeshWireframeChanged,
            onHighlight: onMeshHighlight,
            onShowAll: onShowAllMeshes,
            onHideAll: onHideAllMeshes,
            onWireframeAll: onWireframeAllMeshes,
            onClearAllWireframes: onClearAllWireframes,
          ),
        ],
        const Divider(),
        _buildExpressionButtons(context),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    // Calculate visible triangles from mesh details
    final meshDetails = vrmInfo!['meshDetails'] as List<dynamic>?;
    int visibleTriangles = 0;
    if (meshDetails != null) {
      for (final mesh in meshDetails) {
        final name = mesh['name'] as String;
        if (!hiddenMeshes.contains(name)) {
          visibleTriangles += mesh['triangles'] as int;
        }
      }
    }
    final totalTriangles = vrmInfo!['triangleCount'] as int;

    return ExpansionTile(
      title: Text(Localization.get('basicInfo'), style: const TextStyle(fontWeight: FontWeight.bold)),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      initiallyExpanded: true,
      children: [
        _infoRow(Localization.get('name'), vrmInfo!['name']),
        _infoRow(Localization.get('author'), vrmInfo!['author']),
        const Divider(),
        _infoRow(Localization.get('vertices'), '${vrmInfo!['vertexCount']}'),
        _infoRow(Localization.get('triangles'), '$totalTriangles'),
        _infoRow(Localization.get('trianglesVisible'), '$visibleTriangles'),
        _infoRow(Localization.get('meshes'), '${vrmInfo!['meshCount']}'),
        const Divider(),
        _infoRow(Localization.get('bones'), '${vrmInfo!['boneCount']}'),
        _infoRow(Localization.get('materials'), '${vrmInfo!['materialCount']}'),
        _infoRow(Localization.get('textures'), '${vrmInfo!['textureCount']}'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildExpressionButtons(BuildContext context) {
    final clips = vrmInfo!['blendShapeClips'] as List<dynamic>?;
    if (clips == null || clips.isEmpty) {
      return Text(
        Localization.get('noExpressions'),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return ExpansionTile(
      title: Text('${Localization.get('expressions')} (${clips.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: () {
                  js.resetExpressions();
                  onExpressionChanged(null);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  Localization.get('reset'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              ...clips.map((clip) {
                final name = clip as String;
                final isActive = activeExpression == name;
                return ElevatedButton(
                  onPressed: () {
                    if (isActive) {
                      js.setExpression(name.toJS, (0.0).toJS);
                      onExpressionChanged(null);
                    } else {
                      if (activeExpression != null) {
                        js.setExpression(activeExpression!.toJS, (0.0).toJS);
                      }
                      js.setExpression(name.toJS, (1.0).toJS);
                      onExpressionChanged(name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    backgroundColor: isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    foregroundColor: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  child: Text(name, style: const TextStyle(fontSize: 11)),
                );
              }),
            ],
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
