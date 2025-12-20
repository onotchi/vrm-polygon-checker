import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';
import 'dart:convert';

// JavaScript interop
@JS('loadVRM')
external JSPromise<JSString> _loadVRM(JSString url);

@JS('onPointerDown')
external void _onPointerDown(JSNumber x, JSNumber y, JSNumber button);

@JS('onPointerMove')
external void _onPointerMove(JSNumber x, JSNumber y);

@JS('onPointerUp')
external void _onPointerUp();

@JS('onWheel')
external void _onWheel(JSNumber deltaY);

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
                          const Text('No VRM loaded.\nClick the button to load a sample.'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
