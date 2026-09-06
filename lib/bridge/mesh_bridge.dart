/// Per-mesh control over the model in the 3D viewer.
///
/// A plain Dart interface so the logic that drives it can be tested without a
/// viewer. The JS-backed implementation is in `js_mesh_bridge.dart`.
abstract interface class MeshBridge {
  /// Shows or hides one mesh.
  void setVisible(String name, bool visible);

  /// Shows only [name] and hides every other mesh in one go.
  void focus(String name);

  /// Makes every mesh visible again.
  void showAll();

  /// Draws one mesh as wireframe, or puts its real material back.
  void setWireframe(String name, bool wireframe);

  /// Flashes one mesh so it can be picked out on screen.
  void highlight(String name);
}
