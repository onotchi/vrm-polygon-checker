import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/widgets/info_panel/vrm_summary.dart';

// Localization is never loaded here, so Localization.get() returns the key
// itself. The values are what these tests are about, not the wording.

const Map<String, dynamic> _vrmInfo = {
  'fileName': 'avatar.vrm',
  'vrmVersion': '1.0',
  'name': 'Test Avatar',
  'author': 'Someone',
  'vertexCount': 1000,
  'triangleCount': 600,
  'meshCount': 3,
  'boneCount': 50,
  'materialCount': 4,
  'textureCount': 5,
  'meshDetails': [
    {'name': 'Body', 'triangles': 300, 'materials': 2},
    {'name': 'Hair', 'triangles': 100, 'materials': 1},
    {'name': 'Face', 'triangles': 200, 'materials': 1},
  ],
};

Widget _wrap(
  Map<String, dynamic> vrmInfo, {
  Set<String> hiddenMeshes = const {},
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: VrmSummary(vrmInfo: vrmInfo, hiddenMeshes: hiddenMeshes),
      ),
    ),
  );
}

/// The value shown next to [label] in the info table.
String _valueFor(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  final texts = tester.widgetList<Text>(
    find.descendant(of: row.first, matching: find.byType(Text)),
  );
  return texts.last.data!;
}

void main() {
  group('VrmSummary', () {
    testWidgets('shows the file name and version badge', (tester) async {
      await tester.pumpWidget(_wrap(_vrmInfo));

      expect(find.text('avatar.vrm'), findsOneWidget);
      expect(find.text('VRM 1.0'), findsOneWidget);
    });

    testWidgets('omits the file name row when there is no file name',
        (tester) async {
      final info = Map<String, dynamic>.from(_vrmInfo)..['fileName'] = null;
      await tester.pumpWidget(_wrap(info));

      expect(find.text('avatar.vrm'), findsNothing);
      // The badge lives in the same row, so it goes away with it.
      expect(find.text('VRM 1.0'), findsNothing);
      // The table itself is still there.
      expect(find.text('Test Avatar'), findsOneWidget);
    });

    testWidgets('falls back to a placeholder for an unknown version',
        (tester) async {
      final info = Map<String, dynamic>.from(_vrmInfo)..remove('vrmVersion');
      await tester.pumpWidget(_wrap(info));

      expect(find.text('VRM ?'), findsOneWidget);
    });

    testWidgets('shows the model totals', (tester) async {
      await tester.pumpWidget(_wrap(_vrmInfo));

      expect(_valueFor(tester, 'name'), 'Test Avatar');
      expect(_valueFor(tester, 'author'), 'Someone');
      expect(_valueFor(tester, 'vertices'), '1000');
      expect(_valueFor(tester, 'triangles'), '600');
      expect(_valueFor(tester, 'meshes'), '3');
      expect(_valueFor(tester, 'bones'), '50');
      expect(_valueFor(tester, 'materials'), '4');
      expect(_valueFor(tester, 'textures'), '5');
    });

    testWidgets('counts every mesh as visible when none are hidden',
        (tester) async {
      await tester.pumpWidget(_wrap(_vrmInfo));

      expect(_valueFor(tester, 'trianglesVisible'), '600');
    });

    testWidgets('leaves out hidden meshes from the visible count',
        (tester) async {
      await tester.pumpWidget(_wrap(_vrmInfo, hiddenMeshes: const {'Body'}));

      // 600 total - 300 for Body
      expect(_valueFor(tester, 'trianglesVisible'), '300');
      // The total is unaffected.
      expect(_valueFor(tester, 'triangles'), '600');
    });

    testWidgets('reports zero visible triangles when everything is hidden',
        (tester) async {
      await tester.pumpWidget(_wrap(
        _vrmInfo,
        hiddenMeshes: const {'Body', 'Hair', 'Face'},
      ));

      expect(_valueFor(tester, 'trianglesVisible'), '0');
    });
  });
}
