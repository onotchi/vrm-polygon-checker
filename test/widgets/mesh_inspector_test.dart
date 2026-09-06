import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/widgets/info_panel/mesh_inspector.dart';

// Localization is never loaded here, so Localization.get() returns the key
// itself -- 'meshDetails', 'showAll' and so on are those keys, not wording.

const _meshes = [
  {'name': 'Body', 'triangles': 300, 'materials': 2},
  {'name': 'Hair', 'triangles': 100, 'materials': 1},
  {'name': 'Face', 'triangles': 200, 'materials': 1},
];

Widget _wrap({
  String sortKey = 'none',
  bool sortAscending = true,
  Set<String> hiddenMeshes = const {},
  Set<String> wireframeMeshes = const {},
  String? focusedMesh,
  ValueChanged<String>? onHighlight,
  ValueChanged<String>? onFocusChanged,
  ValueChanged<String>? onVisibilityChanged,
  ValueChanged<String>? onWireframeChanged,
  ValueChanged<String>? onSortChanged,
  VoidCallback? onSortReset,
  VoidCallback? onShowAll,
  VoidCallback? onHideAll,
  VoidCallback? onWireframeAll,
  VoidCallback? onClearAllWireframes,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MeshInspector(
          meshDetails: _meshes,
          hiddenMeshes: hiddenMeshes,
          wireframeMeshes: wireframeMeshes,
          focusedMesh: focusedMesh,
          sortKey: sortKey,
          sortAscending: sortAscending,
          onSortChanged: onSortChanged ?? (_) {},
          onSortReset: onSortReset ?? () {},
          onVisibilityChanged: onVisibilityChanged ?? (_) {},
          onFocusChanged: onFocusChanged ?? (_) {},
          onWireframeChanged: onWireframeChanged ?? (_) {},
          onHighlight: onHighlight ?? (_) {},
          onShowAll: onShowAll ?? () {},
          onHideAll: onHideAll ?? () {},
          onWireframeAll: onWireframeAll ?? () {},
          onClearAllWireframes: onClearAllWireframes ?? () {},
        ),
      ),
    ),
  );
}

/// The innermost Row of the given mesh's list entry, which holds that row's
/// own visibility and wireframe icons.
Finder _rowOf(String meshName) =>
    find.ancestor(of: find.text(meshName), matching: find.byType(Row)).first;

/// Opens the collapsed tile so the mesh rows are reachable.
Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.text('meshDetails (3)'));
  await tester.pumpAndSettle();
}

/// Mesh names in the order they are laid out on screen.
List<String> _displayedOrder(WidgetTester tester) {
  final names = ['Body', 'Hair', 'Face'];
  names.sort((a, b) => tester
      .getTopLeft(find.text(a))
      .dy
      .compareTo(tester.getTopLeft(find.text(b)).dy));
  return names;
}

void main() {
  group('MeshInspector sorting', () {
    testWidgets('keeps the original order when no sort is set', (tester) async {
      await tester.pumpWidget(_wrap(sortKey: 'none'));
      await _expand(tester);

      expect(_displayedOrder(tester), ['Body', 'Hair', 'Face']);
    });

    testWidgets('sorts by triangle count ascending', (tester) async {
      await tester.pumpWidget(_wrap(sortKey: 'triangles', sortAscending: true));
      await _expand(tester);

      expect(_displayedOrder(tester), ['Hair', 'Face', 'Body']);
    });

    testWidgets('sorts by triangle count descending', (tester) async {
      await tester.pumpWidget(_wrap(sortKey: 'triangles', sortAscending: false));
      await _expand(tester);

      expect(_displayedOrder(tester), ['Body', 'Face', 'Hair']);
    });

    testWidgets('sorts by name ascending', (tester) async {
      await tester.pumpWidget(_wrap(sortKey: 'name', sortAscending: true));
      await _expand(tester);

      expect(_displayedOrder(tester), ['Body', 'Face', 'Hair']);
    });

    testWidgets('sorts by name descending', (tester) async {
      await tester.pumpWidget(_wrap(sortKey: 'name', sortAscending: false));
      await _expand(tester);

      expect(_displayedOrder(tester), ['Hair', 'Face', 'Body']);
    });
  });

  group('MeshInspector bulk actions', () {
    testWidgets('offers hide-all while any mesh is visible', (tester) async {
      await tester.pumpWidget(_wrap());
      await _expand(tester);

      expect(find.text('hideAll'), findsOneWidget);
      expect(find.text('showAll'), findsNothing);
    });

    testWidgets('flips to show-all once every mesh is hidden', (tester) async {
      await tester.pumpWidget(_wrap(
        hiddenMeshes: const {'Body', 'Hair', 'Face'},
      ));
      await _expand(tester);

      expect(find.text('showAll'), findsOneWidget);
      expect(find.text('hideAll'), findsNothing);
    });

    testWidgets('still offers hide-all when only some are hidden',
        (tester) async {
      await tester.pumpWidget(_wrap(hiddenMeshes: const {'Body'}));
      await _expand(tester);

      expect(find.text('hideAll'), findsOneWidget);
    });

    testWidgets('flips the wireframe action once every mesh is wireframed',
        (tester) async {
      await tester.pumpWidget(_wrap(
        wireframeMeshes: const {'Body', 'Hair', 'Face'},
      ));
      await _expand(tester);

      expect(find.text('wireframeOff'), findsOneWidget);
      expect(find.text('wireframeOn'), findsNothing);
    });

    testWidgets('reports show-all and hide-all separately', (tester) async {
      var shown = 0;
      var hidden = 0;

      await tester.pumpWidget(_wrap(
        onShowAll: () => shown++,
        onHideAll: () => hidden++,
      ));
      await _expand(tester);

      await tester.tap(find.text('hideAll'));
      expect(hidden, 1);
      expect(shown, 0);
    });

    testWidgets('reports show-all once every mesh is hidden', (tester) async {
      var shown = 0;
      var hidden = 0;

      await tester.pumpWidget(_wrap(
        hiddenMeshes: const {'Body', 'Hair', 'Face'},
        onShowAll: () => shown++,
        onHideAll: () => hidden++,
      ));
      await _expand(tester);

      await tester.tap(find.text('showAll'));
      expect(shown, 1);
      expect(hidden, 0);
    });

    testWidgets('reports wireframe-all while some meshes are plain',
        (tester) async {
      var wireframed = 0;
      var cleared = 0;

      await tester.pumpWidget(_wrap(
        onWireframeAll: () => wireframed++,
        onClearAllWireframes: () => cleared++,
      ));
      await _expand(tester);

      await tester.tap(find.text('wireframeOn'));
      expect(wireframed, 1);
      expect(cleared, 0);
    });

    testWidgets('reports clear-wireframes once every mesh is wireframed',
        (tester) async {
      var wireframed = 0;
      var cleared = 0;

      await tester.pumpWidget(_wrap(
        wireframeMeshes: const {'Body', 'Hair', 'Face'},
        onWireframeAll: () => wireframed++,
        onClearAllWireframes: () => cleared++,
      ));
      await _expand(tester);

      await tester.tap(find.text('wireframeOff'));
      expect(cleared, 1);
      expect(wireframed, 0);
    });
  });

  group('MeshInspector row interaction', () {
    testWidgets('reports a tapped mesh for highlighting', (tester) async {
      String? highlighted;

      await tester.pumpWidget(_wrap(onHighlight: (name) => highlighted = name));
      await _expand(tester);

      await tester.tap(find.text('Hair'));
      expect(highlighted, 'Hair');
    });

    testWidgets('reports a long-pressed mesh for focus', (tester) async {
      String? focused;

      await tester.pumpWidget(_wrap(onFocusChanged: (name) => focused = name));
      await _expand(tester);

      await tester.longPress(find.text('Face'));
      expect(focused, 'Face');
    });

    testWidgets('shows the triangle and material counts per mesh',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await _expand(tester);

      expect(find.text('300 tris, 2 mats'), findsOneWidget);
      expect(find.text('100 tris, 1 mat'), findsOneWidget);
    });

    testWidgets('reports the mesh whose visibility icon was tapped',
        (tester) async {
      String? toggled;

      await tester
          .pumpWidget(_wrap(onVisibilityChanged: (name) => toggled = name));
      await _expand(tester);

      await tester.tap(find.descendant(
        of: _rowOf('Hair'),
        matching: find.byIcon(Icons.visibility),
      ));
      expect(toggled, 'Hair');
    });

    testWidgets('shows a struck-through eye for a hidden mesh', (tester) async {
      await tester.pumpWidget(_wrap(hiddenMeshes: const {'Hair'}));
      await _expand(tester);

      expect(
        find.descendant(
          of: _rowOf('Hair'),
          matching: find.byIcon(Icons.visibility_off),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _rowOf('Body'),
          matching: find.byIcon(Icons.visibility),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reports the mesh whose wireframe icon was tapped',
        (tester) async {
      String? toggled;

      await tester
          .pumpWidget(_wrap(onWireframeChanged: (name) => toggled = name));
      await _expand(tester);

      await tester.tap(find.descendant(
        of: _rowOf('Face'),
        matching: find.byIcon(Icons.grid_on),
      ));
      expect(toggled, 'Face');
    });
  });

  group('MeshInspector sort controls', () {
    testWidgets('reports the sort key of the tapped button', (tester) async {
      final requested = <String>[];

      await tester.pumpWidget(_wrap(onSortChanged: requested.add));

      await tester.tap(find.byTooltip('sortByPolygons'));
      await tester.tap(find.byTooltip('sortByName'));

      expect(requested, ['triangles', 'name']);
    });

    testWidgets('reports a sort reset separately', (tester) async {
      var resets = 0;
      final requested = <String>[];

      await tester.pumpWidget(_wrap(
        onSortChanged: requested.add,
        onSortReset: () => resets++,
      ));

      await tester.tap(find.byTooltip('sortReset'));

      expect(resets, 1);
      expect(requested, isEmpty);
    });
  });
}
