import 'dart:js_interop';

import 'expression_bridge.dart';
import '../js_interop.dart' as js;

/// [ExpressionBridge] backed by the three.js viewer.
class JsExpressionBridge implements ExpressionBridge {
  const JsExpressionBridge();

  @override
  void setWeight(String name, double weight) =>
      js.setExpression(name.toJS, weight.toJS);

  @override
  void resetAll() => js.resetExpressions();
}
