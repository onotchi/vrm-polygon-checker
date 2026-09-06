import 'dart:collection';

import 'bridge/mesh_bridge.dart';

/// Which meshes are hidden, wireframed or focused, and how those states change.
///
/// The viewer itself only takes per-mesh commands, so the bookkeeping that
/// makes focus reversible -- remembering what was hidden before it started --
/// lives here.
class MeshController {
  MeshController(this._bridge);

  final MeshBridge _bridge;

  final Set<String> _hidden = {};
  final Set<String> _wireframed = {};
  String? _focused;

  /// What was hidden before focus started, so unfocusing can put it back.
  /// Null whenever no focus is in progress.
  Set<String>? _hiddenBeforeFocus;

  Set<String> get hidden => UnmodifiableSetView(_hidden);
  Set<String> get wireframed => UnmodifiableSetView(_wireframed);
  String? get focused => _focused;

  /// Shows a hidden mesh, or hides a visible one.
  void toggleVisibility(String name) {
    final visible = _hidden.contains(name);
    _bridge.setVisible(name, visible);
    if (visible) {
      _hidden.remove(name);
    } else {
      _hidden.add(name);
    }
  }

  /// Focuses [name] so it is the only mesh on screen, or lifts the focus when
  /// it is already the focused one.
  ///
  /// [allMeshNames] is every mesh in the model, needed to know what to hide on
  /// the way in and what to restore on the way out.
  void toggleFocus(String name, List<String> allMeshNames) {
    if (_focused == name) {
      _focused = null;
      _hidden.clear();

      final before = _hiddenBeforeFocus;
      if (before != null) {
        _hidden.addAll(before);
        // Focus hid these in one command; putting them back takes one command
        // per mesh, since each returns to whatever it was before.
        for (final mesh in allMeshNames) {
          _bridge.setVisible(mesh, !_hidden.contains(mesh));
        }
      }
      _hiddenBeforeFocus = null;
      return;
    }

    // Moving focus from one mesh to another keeps the set remembered from
    // before the first focus: that is the state the user expects back.
    if (_focused == null) {
      _hiddenBeforeFocus = Set.of(_hidden);
    }
    _bridge.focus(name);
    _focused = name;
    _hidden
      ..clear()
      ..addAll(allMeshNames.where((mesh) => mesh != name));
  }

  /// Draws [name] as wireframe, or puts its real material back.
  void toggleWireframe(String name) {
    final wireframe = !_wireframed.contains(name);
    _bridge.setWireframe(name, wireframe);
    if (wireframe) {
      _wireframed.add(name);
    } else {
      _wireframed.remove(name);
    }
  }

  /// Flashes a mesh. Nothing is remembered: the viewer fades it back itself.
  void highlight(String name) => _bridge.highlight(name);

  /// Makes every mesh visible, lifting any focus.
  void showAll() {
    _hidden.clear();
    _focused = null;
    _hiddenBeforeFocus = null;
    _bridge.showAll();
  }

  /// Hides every mesh, lifting any focus.
  void hideAll(List<String> allMeshNames) {
    _focused = null;
    _hiddenBeforeFocus = null;
    _hidden
      ..clear()
      ..addAll(allMeshNames);
    for (final mesh in allMeshNames) {
      _bridge.setVisible(mesh, false);
    }
  }

  /// Draws every mesh as wireframe, leaving already-wireframed ones alone.
  void wireframeAll(List<String> allMeshNames) {
    for (final mesh in allMeshNames) {
      if (_wireframed.add(mesh)) {
        _bridge.setWireframe(mesh, true);
      }
    }
  }

  /// Puts every wireframed mesh back to its real material.
  void clearAllWireframes() {
    for (final mesh in _wireframed) {
      _bridge.setWireframe(mesh, false);
    }
    _wireframed.clear();
  }

  /// Drops all tracked state without touching the viewer, for when the model is
  /// replaced and these meshes no longer exist.
  void forget() {
    _hidden.clear();
    _wireframed.clear();
    _focused = null;
    _hiddenBeforeFocus = null;
  }
}
