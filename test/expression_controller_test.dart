import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/bridge/expression_bridge.dart';
import 'package:vrm_polygon_checker/expression_controller.dart';

/// Records the calls in order, which is the point of most of these tests.
class FakeExpressionBridge implements ExpressionBridge {
  final List<String> calls = [];

  @override
  void setWeight(String name, double weight) => calls.add('$name=$weight');

  @override
  void resetAll() => calls.add('resetAll');
}

void main() {
  late FakeExpressionBridge bridge;
  late ExpressionController controller;

  setUp(() {
    bridge = FakeExpressionBridge();
    controller = ExpressionController(bridge);
  });

  group('ExpressionController.select', () {
    test('starts with nothing applied', () {
      expect(controller.active, isNull);
      expect(bridge.calls, isEmpty);
    });

    test('applies an expression at full weight', () {
      controller.select('happy');

      expect(bridge.calls, ['happy=1.0']);
      expect(controller.active, 'happy');
    });

    test('turns the previous expression down before applying the next', () {
      controller.select('happy');
      bridge.calls.clear();

      controller.select('angry');

      // The order matters: applying the new one first would briefly leave both
      // at full weight, and the viewer blends them.
      expect(bridge.calls, ['happy=0.0', 'angry=1.0']);
      expect(controller.active, 'angry');
    });

    test('clears the current expression when given null', () {
      controller.select('happy');
      bridge.calls.clear();

      controller.select(null);

      expect(bridge.calls, ['happy=0.0']);
      expect(controller.active, isNull);
    });

    test('does nothing to the viewer when clearing with none applied', () {
      controller.select(null);

      expect(bridge.calls, isEmpty);
      expect(controller.active, isNull);
    });

    test('re-selecting the active expression re-applies it once', () {
      controller.select('happy');
      bridge.calls.clear();

      controller.select('happy');

      expect(bridge.calls, ['happy=0.0', 'happy=1.0']);
      expect(controller.active, 'happy');
    });
  });

  group('ExpressionController.reset', () {
    test('clears everything, not only the tracked expression', () {
      controller.select('happy');
      bridge.calls.clear();

      controller.reset();

      expect(bridge.calls, ['resetAll']);
      expect(controller.active, isNull);
    });

    test('works with nothing applied', () {
      controller.reset();

      expect(bridge.calls, ['resetAll']);
      expect(controller.active, isNull);
    });

    test('leaves no stale expression to turn down afterwards', () {
      controller.select('happy');
      controller.reset();
      bridge.calls.clear();

      controller.select('angry');

      expect(bridge.calls, ['angry=1.0']);
    });
  });

  group('ExpressionController.forget', () {
    test('drops the tracked expression without touching the viewer', () {
      controller.select('happy');
      bridge.calls.clear();

      controller.forget();

      expect(bridge.calls, isEmpty);
      expect(controller.active, isNull);
    });

    test('does not turn down an expression that belonged to the old model', () {
      controller.select('happy');
      // As if a different VRM was loaded: the old expression is gone with it.
      controller.forget();
      bridge.calls.clear();

      controller.select('angry');

      expect(bridge.calls, ['angry=1.0']);
    });
  });
}
