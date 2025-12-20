import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:convert';

// JavaScript interop
@JS('loadVRM')
external JSPromise<JSString> _loadVRM(JSString url);

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary.withAlpha(200),
        title: const Text('VRM Viewer'),
      ),
      body: Stack(
        children: [
          // UI overlay
          Positioned(
            right: 16,
            top: 16,
            child: Card(
              color: Colors.white.withAlpha(230),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
