import 'dart:js_interop';

import 'mesh_bridge.dart';
import '../js_interop.dart' as js;

/// [MeshBridge] backed by the three.js viewer.
class JsMeshBridge implements MeshBridge {
  const JsMeshBridge();

  @override
  void setVisible(String name, bool visible) =>
      js.setMeshVisibility(name.toJS, visible.toJS);

  @override
  void focus(String name) => js.focusMesh(name.toJS);

  @override
  void showAll() => js.showAllMeshes();

  @override
  void setWireframe(String name, bool wireframe) {
    if (wireframe) {
      js.showWireframe(name.toJS);
    } else {
      js.clearWireframe(name.toJS);
    }
  }

  @override
  void highlight(String name) => js.highlightMesh(name.toJS);
}
