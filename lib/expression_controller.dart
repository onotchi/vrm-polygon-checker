import 'bridge/expression_bridge.dart';

/// Applies one expression at a time to the viewer and remembers which.
///
/// The viewer has no notion of "the current expression" -- it only takes
/// per-expression weights -- so keeping that here is what makes switching
/// cleanly possible.
class ExpressionController {
  ExpressionController(this._bridge);

  final ExpressionBridge _bridge;
  String? _active;

  /// The expression currently applied, or null when none is.
  String? get active => _active;

  /// Applies [name], or clears the current expression when it is null.
  ///
  /// The previous expression is always turned back down first, so switching
  /// never leaves two of them applied at once.
  void select(String? name) {
    if (_active != null) {
      _bridge.setWeight(_active!, 0);
    }
    if (name != null) {
      _bridge.setWeight(name, 1);
    }
    _active = name;
  }

  /// Clears every expression in the viewer, not just the tracked one.
  void reset() {
    _bridge.resetAll();
    _active = null;
  }

  /// Drops the tracked expression without touching the viewer, for when the
  /// model is replaced and the old expression went with it.
  void forget() {
    _active = null;
  }
}
