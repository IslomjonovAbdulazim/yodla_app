import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool loading;
  final FutureOr<void> Function() onPressed;
  final Color background;
  final Color foreground;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.enabled = true,
    this.loading = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  static const Curve _curve = Curves.easeIn;
  static const double _shadowHeight = 4;
  double _position = 4;

  bool loading = false;
  CancelableOperation? operation;

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading) {
      setState(() => loading = widget.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = 56 - _shadowHeight;
    return GestureDetector(
      onTapDown: widget.enabled ? _pressed : null,
      onTapUp: widget.enabled ? _unPressedOnTapUp : null,
      onTapCancel: widget.enabled ? _unPressed : null,
      child: SizedBox(
        height: height + _shadowHeight,
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color:
                      widget.enabled
                          ? darken(widget.background, ShadowDegree.light)
                          : darken(Colors.grey, ShadowDegree.light),
                  borderRadius: _getBorderRadius(),
                ),
              ),
            ),
            AnimatedPositioned(
              curve: _curve,
              duration: Duration(milliseconds: 70),
              bottom: _position,
              left: 0,
              right: 0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: widget.enabled ? widget.background : Colors.grey,
                  borderRadius: _getBorderRadius(),
                ),
                child:
                    loading
                        ? CupertinoActivityIndicator(color: widget.foreground)
                        : Padding(
                          padding: const EdgeInsets.all(0),
                          child: Center(child: widget.child),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pressed(_) {
    setState(() {
      _position = 0;
    });
  }

  void _unPressedOnTapUp(_) => _unPressed();

  void _unPressed() async {
    setState(() {
      _position = 4;
    });
    if (operation != null) {
      return operation!.cancel();
    }
    if (!widget.enabled) return;
    if (loading) return;
    final result = widget.onPressed();
    if (result is Future) {
      operation = CancelableOperation.fromFuture(result);
      setState(() => loading = true);
      await operation!.valueOrCancellation();
      setState(() => loading = false);
      operation = null;
    }
  }

  BorderRadius? _getBorderRadius() {
    return BorderRadius.circular(24);
  }
}

Color darken(Color color, ShadowDegree degree) {
  double amount = degree == ShadowDegree.dark ? 0.3 : 0.12;
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

enum ShadowDegree { light, dark }
