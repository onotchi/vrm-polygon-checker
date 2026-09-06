import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/widgets/info_panel/expression_controls.dart';

// Localization is never loaded in these tests, so Localization.get() returns the
// key itself. That is what the finders below look for: the point is which
// widgets appear and what the callbacks report, not the wording.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ExpressionControls', () {
    testWidgets('shows a placeholder when the VRM has no expressions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ExpressionControls(
            clips: null,
            activeExpression: null,
            onSelected: (_) {},
            onReset: () {},
          ),
        ),
      );

      expect(find.text('noExpressions'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('treats an empty clip list as no expressions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpressionControls(
            clips: const [],
            activeExpression: null,
            onSelected: (_) {},
            onReset: () {},
          ),
        ),
      );

      expect(find.text('noExpressions'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('reports the tapped expression', (tester) async {
      String? selected;
      var callCount = 0;

      await tester.pumpWidget(
        _wrap(
          ExpressionControls(
            clips: const ['happy', 'angry'],
            activeExpression: null,
            onSelected: (name) {
              selected = name;
              callCount++;
            },
            onReset: () {},
          ),
        ),
      );

      // The tile starts collapsed, so open it before reaching the buttons.
      await tester.tap(find.text('expressions (2)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('happy'));
      expect(callCount, 1);
      expect(selected, 'happy');
    });

    testWidgets('reports null when the active expression is tapped again', (
      tester,
    ) async {
      String? selected = 'unset';

      await tester.pumpWidget(
        _wrap(
          ExpressionControls(
            clips: const ['happy', 'angry'],
            activeExpression: 'happy',
            onSelected: (name) => selected = name,
            onReset: () {},
          ),
        ),
      );

      await tester.tap(find.text('expressions (2)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('happy'));
      expect(selected, isNull);
    });

    testWidgets('reports reset separately from selection', (tester) async {
      var resets = 0;
      var selections = 0;

      await tester.pumpWidget(
        _wrap(
          ExpressionControls(
            clips: const ['happy'],
            activeExpression: 'happy',
            onSelected: (_) => selections++,
            onReset: () => resets++,
          ),
        ),
      );

      await tester.tap(find.text('expressions (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('reset'));
      expect(resets, 1);
      expect(selections, 0);
    });
  });
}
