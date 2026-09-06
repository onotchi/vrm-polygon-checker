import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert';
import 'bridge/animation_bridge.dart';
import 'bridge/fullscreen_bridge.dart';
import 'bridge/js_animation_bridge.dart';
import 'bridge/js_expression_bridge.dart';
import 'bridge/js_fullscreen_bridge.dart';
import 'bridge/js_mesh_bridge.dart';
import 'expression_controller.dart';
import 'mesh_controller.dart';
import 'localization.dart';
import 'js_interop.dart' as js;
import 'widgets/settings_panel.dart';
import 'widgets/info_panel.dart';
import 'widgets/canvas_area.dart';

/// The one place that binds the widget-facing interfaces to the JS viewer.
const AnimationBridge _animationBridge = JsAnimationBridge();
const FullscreenBridge _fullscreenBridge = JsFullscreenBridge();
const JsExpressionBridge _expressionBridge = JsExpressionBridge();
const JsMeshBridge _meshBridge = JsMeshBridge();

/// Give three_app.js this long to finish importing before starting anyway.
const _threeAppReadyTimeout = Duration(seconds: 10);

/// Keeps the document's `lang` attribute in step with the loaded language.
void _applyDocumentLanguage(AppLanguage language) {
  (web.document.documentElement as web.HTMLElement?)?.lang = language.name;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Registered before the first load, so no language change goes unnoticed.
  Localization.onLanguageChanged = _applyDocumentLanguage;
  await Localization.load(AppLanguage.ja);

  // three_app.js imports three.js from a CDN while Flutter boots from a local
  // script, so the JS side is not necessarily there when the first widget calls
  // into it. Wait for it before building any UI that talks to it.
  var isThreeAppReady = true;
  try {
    await js.threeAppReady.toDart.timeout(_threeAppReadyTimeout);
  } catch (e) {
    // Either the script failed outright or it never finished. Both leave every
    // window function undefined, so the viewer cannot be built at all.
    isThreeAppReady = false;
    debugPrint('three_app.js is unavailable: $e');
  }

  runApp(MyApp(isThreeAppReady: isThreeAppReady));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isThreeAppReady});

  final bool isThreeAppReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM Polygon Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      home: isThreeAppReady
          ? const VRMViewerPage()
          : const ThreeAppUnavailablePage(),
    );
  }
}

/// Shown when three_app.js never became available. Every control in the viewer
/// calls into it, so there is nothing safe to offer here but a way to retry.
class ThreeAppUnavailablePage extends StatelessWidget {
  const ThreeAppUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  Localization.get('viewerInitFailed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Localization.get('viewerInitFailedDetail'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => web.window.location.reload(),
                  icon: const Icon(Icons.refresh),
                  label: Text(Localization.get('reload')),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // Expression state, owned by the controller so the "turn the old one down
  // first" rule lives in one testable place.
  final ExpressionController _expressions =
      ExpressionController(_expressionBridge);

  // Mesh state, owned by the controller so the focus bookkeeping lives in one
  // testable place.
  final MeshController _meshes = MeshController(_meshBridge);
  String _meshSortKey = 'none';
  bool _meshSortAscending = true;

  // Settings state
  double _ambientIntensity = 2.0;
  double _directionalIntensity = 1.0;
  bool _gridVisible = true;
  bool _shadowVisible = true;
  Color _backgroundColor = const Color(0xFFFFFFFF);
  bool _antialiasEnabled = false;
  double _cameraFov = 45.0;

  // Turntable
  bool _turntableEnabled = false;
  double _turntableSpeed = 15.0;

  // Panel width
  double _infoPanelWidth = 320;
  static const double _settingsPanelWidth = 200;

  // Side panel visibility (click the canvas to bring them back)
  bool _panelsVisible = true;

  void _setPanelsVisible(bool visible) {
    setState(() => _panelsVisible = visible);
    js.setPanelLayout(
      (visible ? _settingsPanelWidth : 0.0).toJS,
      (visible ? _infoPanelWidth : 0.0).toJS,
    );
  }

  // Dragging the panel edge changes how much room is left for the canvas, so
  // the JS side needs the new width to keep the canvas and camera aspect in
  // step with the Flutter layout.
  void _setInfoPanelWidth(double width) {
    setState(() => _infoPanelWidth = width);
    js.setPanelLayout(_settingsPanelWidth.toJS, width.toJS);
  }

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
        // The new model has none of the old model's expressions applied.
        _expressions.forget();
        // The JS side rebuilds the animation for the new model and starts it
        // playing from the top. The seek bar is keyed on this map, so handing
        // it a fresh one makes it start over too; otherwise it keeps the old
        // paused state and shows "play" while the clip is actually running.
        final animation = _animationInfo;
        if (animation != null) {
          _animationInfo = Map<String, dynamic>.from(animation);
        }
        // None of the old model's meshes exist on the new one.
        _meshes.forget();
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

  /// Every mesh name in the loaded model. The controller needs it to know what
  /// to hide when focusing, and what to put back when the focus is lifted.
  List<String> get _allMeshNames {
    final meshes = _vrmInfo?['meshDetails'] as List?;
    if (meshes == null) return const [];
    return [for (final m in meshes) m['name'] as String];
  }

  void _handleMeshVisibilityChanged(String name) {
    setState(() => _meshes.toggleVisibility(name));
  }

  void _handleMeshFocusChanged(String name) {
    setState(() => _meshes.toggleFocus(name, _allMeshNames));
  }

  void _handleExpressionSelected(String? name) {
    setState(() => _expressions.select(name));
  }

  void _handleExpressionReset() {
    setState(() => _expressions.reset());
  }

  void _handleMeshHighlight(String name) {
    _meshes.highlight(name);
  }

  void _handleMeshWireframeChanged(String name) {
    setState(() => _meshes.toggleWireframe(name));
  }

  void _showAllMeshes() {
    setState(() => _meshes.showAll());
  }

  void _hideAllMeshes() {
    setState(() => _meshes.hideAll(_allMeshNames));
  }

  void _wireframeAllMeshes() {
    setState(() => _meshes.wireframeAll(_allMeshNames));
  }

  void _clearAllWireframes() {
    setState(() => _meshes.clearAllWireframes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          if (_panelsVisible)
            SettingsPanel(
              ambientIntensity: _ambientIntensity,
              directionalIntensity: _directionalIntensity,
              gridVisible: _gridVisible,
              shadowVisible: _shadowVisible,
              backgroundColor: _backgroundColor,
              antialiasEnabled: _antialiasEnabled,
              cameraFov: _cameraFov,
              onAmbientChanged: (value) => setState(() => _ambientIntensity = value),
              onDirectionalChanged: (value) => setState(() => _directionalIntensity = value),
              onCameraFovChanged: (value) => setState(() => _cameraFov = value),
              onGridVisibleChanged: (value) => setState(() => _gridVisible = value),
              onShadowVisibleChanged: (value) => setState(() => _shadowVisible = value),
              onBackgroundColorChanged: (value) => setState(() => _backgroundColor = value),
              onAntialiasChanged: (value) => setState(() => _antialiasEnabled = value),
              onLanguageChanged: () => setState(() {}),
              fullscreenBridge: _fullscreenBridge,
              onHidePanels: () => _setPanelsVisible(false),
              turntableEnabled: _turntableEnabled,
              turntableSpeed: _turntableSpeed,
              onTurntableEnabledChanged: (value) =>
                  setState(() => _turntableEnabled = value),
              onTurntableSpeedChanged: (value) =>
                  setState(() => _turntableSpeed = value),
            ),
          CanvasArea(
            onTap: _panelsVisible ? null : () => _setPanelsVisible(true),
          ),
          if (_panelsVisible)
            SizedBox(
              width: _infoPanelWidth,
              child: InfoPanel(
                width: _infoPanelWidth,
                vrmInfo: _vrmInfo,
                animationInfo: _animationInfo,
                isLoading: _isLoading,
                isLoadingAnimation: _isLoadingAnimation,
                errorMessage: _errorMessage,
                activeExpression: _expressions.active,
                focusedMesh: _meshes.focused,
                wireframeMeshes: _meshes.wireframed,
                hiddenMeshes: _meshes.hidden,
                meshSortKey: _meshSortKey,
                meshSortAscending: _meshSortAscending,
                onOpenFile: _openFile,
                onOpenAnimation: _openAnimation,
                onStopAnimation: _stopAnimation,
                onExpressionSelected: _handleExpressionSelected,
                onExpressionReset: _handleExpressionReset,
                onMeshVisibilityChanged: _handleMeshVisibilityChanged,
                onMeshFocusChanged: _handleMeshFocusChanged,
                onMeshWireframeChanged: _handleMeshWireframeChanged,
                onMeshHighlight: _handleMeshHighlight,
                onShowAllMeshes: _showAllMeshes,
                onHideAllMeshes: _hideAllMeshes,
                onWireframeAllMeshes: _wireframeAllMeshes,
                onClearAllWireframes: _clearAllWireframes,
                onSortChanged: _toggleMeshSort,
                onSortReset: _resetMeshSort,
                onWidthChanged: _setInfoPanelWidth,
                animationBridge: _animationBridge,
              ),
            ),
        ],
      ),
    );
  }
}
