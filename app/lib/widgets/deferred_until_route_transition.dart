import 'package:flutter/material.dart';

/// Builds expensive content only after the current route finishes entering.
class DeferredUntilRouteTransition extends StatefulWidget {
  const DeferredUntilRouteTransition({
    super.key,
    required this.builder,
    required this.placeholder,
    this.transitionAnimation,
  });

  final WidgetBuilder builder;
  final Widget placeholder;

  /// Overrides the current route animation when the host supplies its own.
  final Animation<double>? transitionAnimation;

  @override
  State<DeferredUntilRouteTransition> createState() =>
      _DeferredUntilRouteTransitionState();
}

class _DeferredUntilRouteTransitionState
    extends State<DeferredUntilRouteTransition> {
  Animation<double>? _routeAnimation;
  bool _hasBoundAnimation = false;
  bool _isReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindAnimation(
      widget.transitionAnimation ?? ModalRoute.of(context)?.animation,
    );
  }

  @override
  void didUpdateWidget(covariant DeferredUntilRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.transitionAnimation, oldWidget.transitionAnimation)) {
      _bindAnimation(
        widget.transitionAnimation ?? ModalRoute.of(context)?.animation,
      );
    }
  }

  void _bindAnimation(Animation<double>? routeAnimation) {
    if (_hasBoundAnimation && identical(routeAnimation, _routeAnimation)) {
      return;
    }

    _routeAnimation?.removeStatusListener(_handleAnimationStatus);
    _routeAnimation = routeAnimation;
    _hasBoundAnimation = true;
    _isReady =
        routeAnimation == null ||
        routeAnimation.status == AnimationStatus.completed;

    if (routeAnimation != null && !_isReady) {
      routeAnimation.addStatusListener(_handleAnimationStatus);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    _routeAnimation?.removeStatusListener(_handleAnimationStatus);
    setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isReady ? widget.builder(context) : widget.placeholder;
  }
}
