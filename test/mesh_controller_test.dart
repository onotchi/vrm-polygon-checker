import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/bridge/mesh_bridge.dart';
import 'package:vrm_polygon_checker/mesh_controller.dart';

/// Records the calls in order, which several of these tests depend on.
class FakeMeshBridge implements MeshBridge {
  final List<String> calls = [];

  @override
  void setVisible(String name, bool visible) =>
      calls.add('setVisible($name,$visible)');

  @override
  void focus(String name) => calls.add('focus($name)');

  @override
  void showAll() => calls.add('showAll');

  @override
  void setWireframe(String name, bool wireframe) =>
      calls.add('setWireframe($name,$wireframe)');

  @override
  void highlight(String name) => calls.add('highlight($name)');
}

const _allMeshes = ['Body', 'Hair', 'Face'];

void main() {
  late FakeMeshBridge bridge;
  late MeshController controller;

  setUp(() {
    bridge = FakeMeshBridge();
    controller = MeshController(bridge);
  });

  group('visibility', () {
    test('starts with everything visible', () {
      expect(controller.hidden, isEmpty);
      expect(bridge.calls, isEmpty);
    });

    test('hides a visible mesh', () {
      controller.toggleVisibility('Hair');

      expect(bridge.calls, ['setVisible(Hair,false)']);
      expect(controller.hidden, {'Hair'});
    });

    test('shows a hidden mesh again', () {
      controller.toggleVisibility('Hair');
      bridge.calls.clear();

      controller.toggleVisibility('Hair');

      expect(bridge.calls, ['setVisible(Hair,true)']);
      expect(controller.hidden, isEmpty);
    });

    test('does not let callers mutate the exposed set', () {
      expect(() => controller.hidden.add('Hair'), throwsUnsupportedError);
    });
  });

  group('focus', () {
    test('hides every other mesh with a single focus command', () {
      controller.toggleFocus('Hair', _allMeshes);

      expect(bridge.calls, ['focus(Hair)']);
      expect(controller.focused, 'Hair');
      expect(controller.hidden, {'Body', 'Face'});
    });

    test('restores an all-visible model when lifted', () {
      controller.toggleFocus('Hair', _allMeshes);
      bridge.calls.clear();

      controller.toggleFocus('Hair', _allMeshes);

      expect(controller.focused, isNull);
      expect(controller.hidden, isEmpty);
      expect(bridge.calls, [
        'setVisible(Body,true)',
        'setVisible(Hair,true)',
        'setVisible(Face,true)',
      ]);
    });

    test('puts back what was hidden before focusing', () {
      controller.toggleVisibility('Body');
      controller.toggleFocus('Hair', _allMeshes);
      bridge.calls.clear();

      controller.toggleFocus('Hair', _allMeshes);

      // Body was hidden by hand beforehand, so it stays hidden.
      expect(controller.hidden, {'Body'});
      expect(bridge.calls, [
        'setVisible(Body,false)',
        'setVisible(Hair,true)',
        'setVisible(Face,true)',
      ]);
    });

    test('keeps the pre-focus state when focus moves to another mesh', () {
      controller.toggleVisibility('Body');
      controller.toggleFocus('Hair', _allMeshes);
      controller.toggleFocus('Face', _allMeshes);

      expect(controller.focused, 'Face');
      expect(controller.hidden, {'Body', 'Hair'});
    });

    test('lifting focus after moving it returns to the original state', () {
      controller.toggleVisibility('Body');
      controller.toggleFocus('Hair', _allMeshes);
      controller.toggleFocus('Face', _allMeshes);
      bridge.calls.clear();

      controller.toggleFocus('Face', _allMeshes);

      // Back to "only Body hidden", the state from before the first focus.
      expect(controller.focused, isNull);
      expect(controller.hidden, {'Body'});
      expect(bridge.calls, [
        'setVisible(Body,false)',
        'setVisible(Hair,true)',
        'setVisible(Face,true)',
      ]);
    });

    test('focusing again after lifting remembers the state at that moment', () {
      controller.toggleFocus('Hair', _allMeshes);
      controller.toggleFocus('Hair', _allMeshes);
      controller.toggleVisibility('Face');
      controller.toggleFocus('Body', _allMeshes);
      bridge.calls.clear();

      controller.toggleFocus('Body', _allMeshes);

      expect(controller.hidden, {'Face'});
    });
  });

  group('wireframe', () {
    test('turns a mesh into wireframe and back', () {
      controller.toggleWireframe('Hair');
      expect(bridge.calls, ['setWireframe(Hair,true)']);
      expect(controller.wireframed, {'Hair'});

      controller.toggleWireframe('Hair');
      expect(bridge.calls.last, 'setWireframe(Hair,false)');
      expect(controller.wireframed, isEmpty);
    });

    test('wireframes every mesh', () {
      controller.wireframeAll(_allMeshes);

      expect(bridge.calls, [
        'setWireframe(Body,true)',
        'setWireframe(Hair,true)',
        'setWireframe(Face,true)',
      ]);
      expect(controller.wireframed, {'Body', 'Hair', 'Face'});
    });

    test('leaves already-wireframed meshes alone', () {
      controller.toggleWireframe('Hair');
      bridge.calls.clear();

      controller.wireframeAll(_allMeshes);

      expect(bridge.calls, [
        'setWireframe(Body,true)',
        'setWireframe(Face,true)',
      ]);
    });

    test('clears every wireframe', () {
      controller.wireframeAll(_allMeshes);
      bridge.calls.clear();

      controller.clearAllWireframes();

      expect(bridge.calls, hasLength(3));
      expect(bridge.calls, everyElement(contains(',false)')));
      expect(controller.wireframed, isEmpty);
    });

    test('wireframe state is independent of visibility', () {
      controller.toggleWireframe('Hair');
      controller.toggleVisibility('Hair');

      expect(controller.wireframed, {'Hair'});
      expect(controller.hidden, {'Hair'});
    });
  });

  group('bulk visibility', () {
    test('shows everything and lifts any focus', () {
      controller.toggleFocus('Hair', _allMeshes);
      bridge.calls.clear();

      controller.showAll();

      expect(bridge.calls, ['showAll']);
      expect(controller.hidden, isEmpty);
      expect(controller.focused, isNull);
    });

    test('hides everything and lifts any focus', () {
      controller.toggleFocus('Hair', _allMeshes);
      bridge.calls.clear();

      controller.hideAll(_allMeshes);

      expect(controller.hidden, {'Body', 'Hair', 'Face'});
      expect(controller.focused, isNull);
      expect(bridge.calls, [
        'setVisible(Body,false)',
        'setVisible(Hair,false)',
        'setVisible(Face,false)',
      ]);
    });

    test('a focus after showAll remembers an empty state', () {
      controller.toggleVisibility('Body');
      controller.showAll();
      controller.toggleFocus('Hair', _allMeshes);
      bridge.calls.clear();

      controller.toggleFocus('Hair', _allMeshes);

      expect(controller.hidden, isEmpty);
    });
  });

  group('highlight', () {
    test('passes it straight through and remembers nothing', () {
      controller.highlight('Hair');

      expect(bridge.calls, ['highlight(Hair)']);
      expect(controller.hidden, isEmpty);
      expect(controller.focused, isNull);
    });
  });

  group('forget', () {
    test('drops every tracked state without touching the viewer', () {
      controller.toggleVisibility('Body');
      controller.toggleWireframe('Hair');
      controller.toggleFocus('Face', _allMeshes);
      bridge.calls.clear();

      controller.forget();

      expect(bridge.calls, isEmpty);
      expect(controller.hidden, isEmpty);
      expect(controller.wireframed, isEmpty);
      expect(controller.focused, isNull);
    });

    test('leaves no stale pre-focus state behind', () {
      controller.toggleVisibility('Body');
      controller.toggleFocus('Hair', _allMeshes);
      // As if a different VRM was loaded while focused.
      controller.forget();

      // Focus and lift it on the new model: nothing from before should return.
      controller.toggleFocus('Hair', _allMeshes);
      controller.toggleFocus('Hair', _allMeshes);

      expect(controller.hidden, isEmpty);
    });
  });
}
