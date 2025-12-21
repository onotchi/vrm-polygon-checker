import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:convert';
import 'localization.dart';
import 'js_interop.dart' as js;
import 'widgets/settings_panel.dart';
import 'widgets/info_panel.dart';
import 'widgets/canvas_area.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Localization.load(AppLanguage.ja);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM Polygon Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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
  // VRM state
  Map<String, dynamic>? _vrmInfo;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation state
  Map<String, dynamic>? _animationInfo;
  bool _isLoadingAnimation = false;

  // Expression state
  String? _activeExpression;

  // Mesh state
  final Set<String> _hiddenMeshes = {};
  String? _focusedMesh;
  Set<String>? _hiddenMeshesBeforeFocus; // Store hidden state before focus
  final Set<String> _wireframeMeshes = {};
  String _meshSortKey = 'none';
  bool _meshSortAscending = true;

  // Settings state
  double _ambientIntensity = 2.0;
  double _directionalIntensity = 1.0;
  bool _gridVisible = true;
  bool _shadowVisible = true;
  Color _backgroundColor = const Color(0xFFFFFFFF);

  // Panel width
  double _infoPanelWidth = 320;

  @override
  void initState() {
    super.initState();
    js.onVRMLoadedCallback = _handleVRMLoaded.toJS;
    js.onVRMALoadedCallback = _handleVRMALoaded.toJS;
    js.onVRMLoadCancelledCallback = _handleVRMLoadCancelled.toJS;
    js.onVRMALoadCancelledCallback = _handleVRMALoadCancelled.toJS;
  }

  @override
  void dispose() {
    js.onVRMLoadedCallback = null;
    js.onVRMALoadedCallback = null;
    js.onVRMLoadCancelledCallback = null;
    js.onVRMALoadCancelledCallback = null;
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
        _hiddenMeshes.clear();
        _focusedMesh = null;
        _wireframeMeshes.clear();
        _meshSortKey = 'none';
        _meshSortAscending = true;
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
    js.openFilePicker();
  }

  void _openAnimation() {
    if (_vrmInfo == null) {
      setState(() {
        _errorMessage = Localization.get('pleaseLoadVrmFirst');
      });
      return;
    }
    setState(() {
      _isLoadingAnimation = true;
      _errorMessage = null;
    });
    js.openVRMAPicker();
  }

  void _stopAnimation() {
    js.stopAnimation();
    setState(() {
      _animationInfo = null;
    });
  }

  void _toggleMeshSort(String key) {
    setState(() {
      if (_meshSortKey == key) {
        // Toggle ascending/descending
        _meshSortAscending = !_meshSortAscending;
      } else {
        _meshSortKey = key;
        _meshSortAscending = true;
      }
    });
  }

  void _resetMeshSort() {
    setState(() {
      _meshSortKey = 'none';
      _meshSortAscending = true;
    });
  }

  void _handleMeshVisibilityChanged(String name) {
    final isHidden = _hiddenMeshes.contains(name);
    final newVisible = isHidden;
    js.setMeshVisibility(name.toJS, newVisible.toJS);
    setState(() {
      if (newVisible) {
        _hiddenMeshes.remove(name);
      } else {
        _hiddenMeshes.add(name);
      }
    });
  }

  void _handleMeshFocusChanged(String name) {
    setState(() {
      if (_focusedMesh == name) {
        // Unfocus: restore previous hidden state
        _focusedMesh = null;
        _hiddenMeshes.clear();
        if (_hiddenMeshesBeforeFocus != null) {
          _hiddenMeshes.addAll(_hiddenMeshesBeforeFocus!);
          // Restore visibility in JS
          final meshes = _vrmInfo?['meshDetails'] as List?;
          if (meshes != null) {
            for (final m in meshes) {
              final meshName = m['name'] as String;
              final shouldBeVisible = !_hiddenMeshes.contains(meshName);
              js.setMeshVisibility(meshName.toJS, shouldBeVisible.toJS);
            }
          }
        }
        _hiddenMeshesBeforeFocus = null;
      } else {
        // Focus: save current hidden state and show only this mesh
        if (_focusedMesh == null) {
          // Only save if not already focusing (switching focus keeps original state)
          _hiddenMeshesBeforeFocus = Set.from(_hiddenMeshes);
        }
        js.focusMesh(name.toJS);
        _focusedMesh = name;
        _hiddenMeshes.clear();
        final meshes = _vrmInfo?['meshDetails'] as List?;
        if (meshes != null) {
          for (final m in meshes) {
            final meshName = m['name'] as String;
            if (meshName != name) {
              _hiddenMeshes.add(meshName);
            }
          }
        }
      }
    });
  }

  void _handleMeshWireframeChanged(String name) {
    setState(() {
      if (_wireframeMeshes.contains(name)) {
        js.clearWireframe(name.toJS);
        _wireframeMeshes.remove(name);
      } else {
        js.showWireframe(name.toJS);
        _wireframeMeshes.add(name);
      }
    });
  }

  void _showAllMeshes() {
    setState(() {
      _hiddenMeshes.clear();
      _focusedMesh = null;
      _hiddenMeshesBeforeFocus = null;
    });
    js.showAllMeshes();
  }

  void _hideAllMeshes() {
    final meshes = _vrmInfo?['meshDetails'] as List?;
    if (meshes == null) return;
    setState(() {
      _focusedMesh = null;
      _hiddenMeshesBeforeFocus = null;
      _hiddenMeshes.clear();
      for (final m in meshes) {
        final name = m['name'] as String;
        js.setMeshVisibility(name.toJS, false.toJS);
        _hiddenMeshes.add(name);
      }
    });
  }

  void _wireframeAllMeshes() {
    final meshes = _vrmInfo?['meshDetails'] as List?;
    if (meshes == null) return;
    setState(() {
      for (final m in meshes) {
        final name = m['name'] as String;
        if (!_wireframeMeshes.contains(name)) {
          js.showWireframe(name.toJS);
          _wireframeMeshes.add(name);
        }
      }
    });
  }

  void _clearAllWireframes() {
    setState(() {
      for (final name in _wireframeMeshes.toList()) {
        js.clearWireframe(name.toJS);
      }
      _wireframeMeshes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          SettingsPanel(
            ambientIntensity: _ambientIntensity,
            directionalIntensity: _directionalIntensity,
            gridVisible: _gridVisible,
            shadowVisible: _shadowVisible,
            backgroundColor: _backgroundColor,
            onAmbientChanged: (value) => setState(() => _ambientIntensity = value),
            onDirectionalChanged: (value) => setState(() => _directionalIntensity = value),
            onGridVisibleChanged: (value) => setState(() => _gridVisible = value),
            onShadowVisibleChanged: (value) => setState(() => _shadowVisible = value),
            onBackgroundColorChanged: (value) => setState(() => _backgroundColor = value),
            onLanguageChanged: () => setState(() {}),
          ),
          const CanvasArea(),
          SizedBox(
            width: _infoPanelWidth,
            child: InfoPanel(
              width: _infoPanelWidth,
              vrmInfo: _vrmInfo,
              animationInfo: _animationInfo,
              isLoading: _isLoading,
              isLoadingAnimation: _isLoadingAnimation,
              errorMessage: _errorMessage,
              activeExpression: _activeExpression,
              focusedMesh: _focusedMesh,
              wireframeMeshes: _wireframeMeshes,
              hiddenMeshes: _hiddenMeshes,
              meshSortKey: _meshSortKey,
              meshSortAscending: _meshSortAscending,
              onOpenFile: _openFile,
              onOpenAnimation: _openAnimation,
              onStopAnimation: _stopAnimation,
              onExpressionChanged: (value) => setState(() => _activeExpression = value),
              onMeshVisibilityChanged: _handleMeshVisibilityChanged,
              onMeshFocusChanged: _handleMeshFocusChanged,
              onMeshWireframeChanged: _handleMeshWireframeChanged,
              onShowAllMeshes: _showAllMeshes,
              onHideAllMeshes: _hideAllMeshes,
              onWireframeAllMeshes: _wireframeAllMeshes,
              onClearAllWireframes: _clearAllWireframes,
              onSortChanged: _toggleMeshSort,
              onSortReset: _resetMeshSort,
              onWidthChanged: (value) => setState(() => _infoPanelWidth = value),
            ),
          ),
        ],
      ),
    );
  }
}
