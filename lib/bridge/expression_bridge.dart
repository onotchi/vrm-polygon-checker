/// Expression (blend shape) control over the model in the 3D viewer.
///
/// A plain Dart interface so the logic that drives it can be tested without a
/// viewer. The JS-backed implementation is in `js_expression_bridge.dart`.
abstract interface class ExpressionBridge {
  /// Sets one expression's weight: 0 for off, 1 for fully applied.
  void setWeight(String name, double weight);

  /// Clears every expression at once.
  void resetAll();
}
