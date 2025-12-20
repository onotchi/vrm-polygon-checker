import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';
import 'dart:convert';

// JavaScript interop
@JS('loadVRM')
external JSPromise<JSString> _loadVRM(JSString url);

@JS('openFilePicker')
external void _openFilePicker();

@JS('onPointerDown')
external void _onPointerDown(JSNumber x, JSNumber y, JSNumber button);

@JS('onPointerMove')
external void _onPointerMove(JSNumber x, JSNumber y);

@JS('onPointerUp')
external void _onPointerUp();

@JS('onWheel')
external void _onWheel(JSNumber deltaY);

// Callback setter for VRM loaded event
@JS('onVRMLoaded')
external set _onVRMLoaded(JSFunction? callback);

Future<Map<String, dynamic>?> loadVRM(String url) async {
  try {
    final result = await _loadVRM(url.toJS).toDart;
    return jsonDecode(result.toDart) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('Error loading VRM: $e');
    return null;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM Viewer',
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

  @override
  void initState() {
    super.initState();
    // Set up callback for file picker and drag & drop
    _onVRMLoaded = _handleVRMLoaded.toJS;
  }

  @override
  void dispose() {
    _onVRMLoaded = null;
    super.dispose();
  }

  void _handleVRMLoaded(JSString resultJson) {
    final result = jsonDecode(resultJson.toDart) as Map<String, dynamic>;
    setState(() {
      _isLoading = false;
      if (result['error'] == null) {
        _vrmInfo = result;
        _errorMessage = null;
      } else {
        _errorMessage = result['error'];
      }
    });
  }

  void _openFile() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _openFilePicker();
  }

  Future<void> _loadSampleVRM() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Sample VRM from three-vrm examples
    const sampleUrl =
        'https://pixiv.github.io/three-vrm/packages/three-vrm/examples/models/VRM1_Constraint_Twist_Sample.vrm';

    final info = await loadVRM(sampleUrl);

    setState(() {
      _isLoading = false;
      if (info != null && info['error'] == null) {
        _vrmInfo = info;
      } else {
        _errorMessage = info?['error'] ?? 'Failed to load VRM';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Left: Three.js canvas area with pointer event forwarding
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
          // Right: Flutter UI panel
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
                          const Text('No VRM loaded.\nDrag & drop a file or use the buttons below.'),
                        const SizedBox(height: 16),
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
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loadSampleVRM,
                            icon: const Icon(Icons.download),
                            label: const Text('Load Sample VRM'),
                          ),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileName != null) ...[
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
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
      ],
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
