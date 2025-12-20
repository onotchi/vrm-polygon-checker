import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';
import 'dart:convert';

// JavaScript interop
@JS('openFilePicker')
external void _openFilePicker();

@JS('openVRMAPicker')
external void _openVRMAPicker();

@JS('stopAnimation')
external JSString _stopAnimation();

@JS('setExpression')
external JSString _setExpression(JSString expressionName, JSNumber value);

@JS('resetExpressions')
external JSString _resetExpressions();

@JS('onPointerDown')
external void _onPointerDown(JSNumber x, JSNumber y, JSNumber button);

@JS('onPointerMove')
external void _onPointerMove(JSNumber x, JSNumber y);

@JS('onPointerUp')
external void _onPointerUp();

@JS('onWheel')
external void _onWheel(JSNumber deltaY);

@JS('setLightIntensity')
external void _setLightIntensity(JSNumber ambient, JSNumber directional);

@JS('highlightMesh')
external JSString _highlightMesh(JSString meshName);

@JS('clearMeshHighlight')
external JSString _clearMeshHighlight();

// Callback setter for VRM loaded event
@JS('onVRMLoaded')
external set _onVRMLoaded(JSFunction? callback);

// Callback setter for VRMA loaded event
@JS('onVRMALoaded')
external set _onVRMALoaded(JSFunction? callback);

// Callback setter for file picker cancelled events
@JS('onVRMLoadCancelled')
external set _onVRMLoadCancelled(JSFunction? callback);

@JS('onVRMALoadCancelled')
external set _onVRMALoadCancelled(JSFunction? callback);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const VRMViewerPage(),
    );
  }
}

class VRMViewerPage extends StatefulWidget {
  const VRMViewerPage({super.key});

  @override
  State<VRMViewerPage> createState() => _VRMViewerPageState();
}

class _VRMViewerPageState extends State<VRMViewerPage> {
  Map<String, dynamic>? _vrmInfo;
  bool _isLoading = false;
  String? _errorMessage;
  double _ambientIntensity = 2.0;
  double _directionalIntensity = 1.0;
  Map<String, dynamic>? _animationInfo;
  bool _isLoadingAnimation = false;
  String? _activeExpression;
  String? _selectedMesh;

  @override
  void initState() {
    super.initState();
    // Set up callback for file picker and drag & drop
    _onVRMLoaded = _handleVRMLoaded.toJS;
    _onVRMALoaded = _handleVRMALoaded.toJS;
    _onVRMLoadCancelled = _handleVRMLoadCancelled.toJS;
    _onVRMALoadCancelled = _handleVRMALoadCancelled.toJS;
  }

  @override
  void dispose() {
    _onVRMLoaded = null;
    _onVRMALoaded = null;
    _onVRMLoadCancelled = null;
    _onVRMALoadCancelled = null;
    super.dispose();
  }

  void _handleVRMLoaded(JSString resultJson) {
    final result = jsonDecode(resultJson.toDart) as Map<String, dynamic>;
    setState(() {
      _isLoading = false;
      if (result['error'] == null) {
        _vrmInfo = result;
        _errorMessage = null;
        _activeExpression = null;
        _selectedMesh = null;
      } else {
        _errorMessage = result['error'];
      }
    });
  }

  void _handleVRMALoaded(JSString resultJson) {
    final result = jsonDecode(resultJson.toDart) as Map<String, dynamic>;
    setState(() {
      _isLoadingAnimation = false;
      if (result['error'] == null) {
        _animationInfo = result;
      } else {
        _errorMessage = result['error'];
      }
    });
  }

  void _handleVRMLoadCancelled() {
    setState(() {
      _isLoading = false;
    });
  }

  void _handleVRMALoadCancelled() {
    setState(() {
      _isLoadingAnimation = false;
    });
  }

  void _openFile() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _openFilePicker();
  }

  void _openAnimation() {
    if (_vrmInfo == null) {
      setState(() {
        _errorMessage = 'Please load a VRM first.';
      });
      return;
    }
    setState(() {
      _isLoadingAnimation = true;
      _errorMessage = null;
    });
    _openVRMAPicker();
  }

  void _stopCurrentAnimation() {
    _stopAnimation();
    setState(() {
      _animationInfo = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Left: Settings panel
          Container(
            width: 200,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: const Text(
                    'Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Lighting controls
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lighting',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ambient', style: TextStyle(fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _ambientIntensity,
                              min: 0,
                              max: 2,
                              onChanged: (value) {
                                setState(() {
                                  _ambientIntensity = value;
                                });
                                _setLightIntensity(
                                  _ambientIntensity.toJS,
                                  _directionalIntensity.toJS,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              _ambientIntensity.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Text('Direct', style: TextStyle(fontSize: 12)),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _directionalIntensity,
                              min: 0,
                              max: 3,
                              onChanged: (value) {
                                setState(() {
                                  _directionalIntensity = value;
                                });
                                _setLightIntensity(
                                  _ambientIntensity.toJS,
                                  _directionalIntensity.toJS,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              _directionalIntensity.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Center: Three.js canvas area with pointer event forwarding
          Expanded(
            child: Listener(
              onPointerDown: (event) {
                _onPointerDown(
                  event.position.dx.toJS,
                  event.position.dy.toJS,
                  event.buttons.toJS,
                );
              },
              onPointerMove: (event) {
                _onPointerMove(
                  event.position.dx.toJS,
                  event.position.dy.toJS,
                );
              },
              onPointerUp: (event) {
                _onPointerUp();
              },
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _onWheel(event.scrollDelta.dy.toJS);
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Right: VRM Info panel
          Container(
            width: 320,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: const Text(
                    'VRM Viewer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _openFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Open VRM File'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingAnimation ? null : _openAnimation,
                            icon: const Icon(Icons.animation),
                            label: const Text('Load Animation (.vrma)'),
                          ),
                        ),
                        if (_animationInfo != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _animationInfo!['fileName'] ?? 'Animation',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _stopCurrentAnimation,
                                    icon: const Icon(Icons.stop),
                                    tooltip: 'Stop Animation',
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'VRM Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          )
                        else if (_vrmInfo != null)
                          _buildInfoTable()
                        else
                          const Text('No VRM loaded.\nDrag & drop a file.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTable() {
    final fileName = _vrmInfo!['fileName'] as String?;
    final meshDetails = _vrmInfo!['meshDetails'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileName != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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
                  'VRM ${_vrmInfo!['vrmVersion'] ?? '?'}',
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
        _infoRow('Name', _vrmInfo!['name']),
        _infoRow('Author', _vrmInfo!['author']),
        const Divider(),
        _infoRow('Vertices', '${_vrmInfo!['vertexCount']}'),
        _infoRow('Triangles', '${_vrmInfo!['triangleCount']}'),
        _infoRow('Meshes', '${_vrmInfo!['meshCount']}'),
        const Divider(),
        _infoRow('Bones', '${_vrmInfo!['boneCount']}'),
        _infoRow('Materials', '${_vrmInfo!['materialCount']}'),
        _infoRow('Textures', '${_vrmInfo!['textureCount']}'),
        if (meshDetails != null && meshDetails.isNotEmpty) ...[
          const Divider(),
          _buildMeshDetails(meshDetails),
        ],
        const Divider(),
        _buildExpressionButtons(),
      ],
    );
  }

  Widget _buildExpressionButtons() {
    final clips = _vrmInfo!['blendShapeClips'] as List<dynamic>?;
    if (clips == null || clips.isEmpty) {
      return const Text(
        'No expressions available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return ExpansionTile(
      title: Text('Expressions (${clips.length})'),
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
              // Reset button
              OutlinedButton(
                onPressed: () {
                  _resetExpressions();
                  setState(() {
                    _activeExpression = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 11)),
              ),
              // Expression buttons
              ...clips.map((clip) {
                final name = clip as String;
                final isActive = _activeExpression == name;
                return ElevatedButton(
                  onPressed: () {
                    if (isActive) {
                      // Turn off
                      _setExpression(name.toJS, (0.0).toJS);
                      setState(() {
                        _activeExpression = null;
                      });
                    } else {
                      // Reset previous and set new
                      if (_activeExpression != null) {
                        _setExpression(_activeExpression!.toJS, (0.0).toJS);
                      }
                      _setExpression(name.toJS, (1.0).toJS);
                      setState(() {
                        _activeExpression = name;
                      });
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

  Widget _buildMeshDetails(List<dynamic> meshDetails) {
    return ExpansionTile(
      title: Text('Mesh Details (${meshDetails.length})'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      children: List.generate(meshDetails.length, (index) {
        final m = meshDetails[index] as Map<String, dynamic>;
        final name = m['name'] as String;
        final tris = m['triangles'] as int;
        final mats = m['materials'] as int;
        final isLast = index == meshDetails.length - 1;
        final isSelected = _selectedMesh == name;
        return InkWell(
          onTap: () {
            if (isSelected) {
              _clearMeshHighlight();
              setState(() {
                _selectedMesh = null;
              });
            } else {
              _highlightMesh(name.toJS);
              setState(() {
                _selectedMesh = name;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  isLast ? '└─ ' : '├─ ',
                  style: const TextStyle(color: Colors.grey),
                ),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
                Text(
                  '$tris tris, $mats mat${mats > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
