import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';

import 'button_content.dart';
import 'common_button_type.dart';
import 'text_styles.dart';

class Button extends StatefulWidget {
  final FutureOr<void> Function()? onPressed;
  final FutureOr<void> Function()? onLongPressed;

  final bool loading;
  final bool enabled;
  final bool? selected;

  final String? text;
  final Widget? child;

  final Color? borderColor;
  final Color? buttonColor;
  final Color? labelColor;

  final CommonButtonType type;
  final Widget? trailing;
  final Widget? leading;
  final EdgeInsets padding;
  final String? anchorText;
  final BoxShape? shape;

  final bool expanded;
  final double radius;
  final MainAxisSize mainAxisSize;

  const Button.primary({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.shape,
    this.expanded = true,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.max,
  }) : type = CommonButtonType.primary,
       selected = null,
       anchorText = null;

  const Button.secondary({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.shape,
    this.expanded = true,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.max,

  }) : type = CommonButtonType.secondary,
       selected = null,
       anchorText = null;

  const Button.tertiary({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(12),
    this.shape,
    this.expanded = false,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.min,
  }) : type = CommonButtonType.tertiary,
       selected = null,
       anchorText = null;

  const Button.white({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.shape,
    this.expanded = true,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.max,
  }) : type = CommonButtonType.white,
       selected = null,
       anchorText = null;

  const Button.radio({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.selected = false,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.anchorText,
    this.shape,
    this.expanded = true,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.max,
  }) : type = CommonButtonType.radio;

  const Button.radioAlt({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.selected = false,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.anchorText,
    this.shape,
    this.expanded = true,
    this.radius = 24,
    this.mainAxisSize = MainAxisSize.max,
  }) : type = CommonButtonType.radioAlt;

  const Button({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.loading = false,
    this.enabled = true,
    this.selected = false,
    this.text,
    this.child,
    this.borderColor,
    this.buttonColor,
    this.labelColor,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.all(14),
    this.anchorText,
    this.shape,
    this.expanded = true,
    this.radius = 24,
    required this.type,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _isPressed = false;
  late bool _loading;

  CancelableOperation? operation;

  @override
  void initState() {
    _loading = widget.loading;
    super.initState();
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading != oldWidget.loading) {
      setState(() => _loading = widget.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!widget.enabled || _loading || widget.onPressed == null) return;
        final result = widget.onPressed!();

        if (result is Future) {
          operation = CancelableOperation.fromFuture(result);
          setState(() => _loading = true);
          await operation!.valueOrCancellation();
          setState(() => _loading = false);
          operation = null;
        }
      },
      onPanDown: _pressed,
      onPanEnd: _unPressedOnTapUp,
      onTapCancel: _unPressed,
      onPanCancel: _unPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 70),
        scale:
            widget.type != CommonButtonType.tertiary || !_isPressed ? 1 : 0.9,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          padding: EdgeInsets.only(
            top:
                !_isPressed || widget.type == CommonButtonType.tertiary ? 0 : 4,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  decoration: BoxDecoration(
                    color: widget.type.getBorderColor(
                      context,
                      widget,
                      _isPressed,
                    ),
                    borderRadius:
                        widget.shape != null
                            ? null
                            : BorderRadius.circular(widget.radius),
                    shape: widget.shape ?? BoxShape.rectangle,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                top: 0,
                left: 0,
                right: 0,
                bottom:
                    !_isPressed || widget.type == CommonButtonType.tertiary
                        ? 4
                        : 0,
                child: Builder(
                  builder: (context) {
                    final child = AnimatedContainer(
                      duration: const Duration(milliseconds: 70),
                      decoration: BoxDecoration(
                        borderRadius:
                            widget.shape != null
                                ? null
                                : BorderRadius.circular(widget.radius),
                        border: Border.all(
                          color: widget.type.getBorderColor(
                            context,
                            widget,
                            _isPressed,
                          ),
                          width:
                              widget.type == CommonButtonType.primary ? 0 : 1,
                        ),
                        shape: widget.shape ?? BoxShape.rectangle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.type.getButtonColor(
                              context,
                              widget,
                              _isPressed,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (widget.shape == null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: child,
                      );
                    }
                    return ClipOval(child: child);
                  },
                ),
              ),
              if (widget.anchorText != null)
                Visibility(
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  visible: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    padding: widget.padding.copyWith(
                      bottom:
                          !_isPressed ||
                                  widget.type == CommonButtonType.tertiary
                              ? widget.padding.bottom + 4
                              : widget.padding.bottom,
                    ),
                    child: Row(
                      mainAxisSize:
                          widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        if (widget.leading != null ||
                            widget.trailing != null) ...[
                          widget.leading != null
                              ? widget.leading!
                              : const SizedBox(width: 24),
                          const SizedBox(width: 8),
                        ],
                        Builder(
                          builder: (context) {
                            final content = Center(
                              child: Text(
                                widget.anchorText!,
                                style: TextStyles.medium(context).copyWith(
                                  color: widget.type.getLabelColor(
                                    context,
                                    widget,
                                    _isPressed,
                                  ),
                                ),
                              ),
                            );
                            if (!widget.expanded) return content;
                            return Expanded(child: content);
                          },
                        ),
                        if (widget.leading != null ||
                            widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.trailing != null
                              ? widget.trailing!
                              : const SizedBox(width: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                padding: widget.padding.copyWith(
                  bottom:
                      !_isPressed || widget.type == CommonButtonType.tertiary
                          ? widget.padding.bottom + 4
                          : widget.padding.bottom,
                ),
                child: ButtonContent(
                  widget: widget,
                  isPressed: _isPressed,
                  loading: _loading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pressed(_) async {
    if (!widget.enabled || _loading) return;
    if (mounted) {
      setState(() => _isPressed = true);
    }
    if (widget.onLongPressed == null) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isPressed) return;
    if (mounted) {
      setState(() => _isPressed = false);
    }
    widget.onLongPressed?.call();
  }

  void _unPressedOnTapUp(_) {
    if (!_isPressed) return;
    Future.delayed(const Duration(milliseconds: 70)).then((value) async {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
      if (operation != null) {
        return operation!.cancel();
      }
    });
  }

  void _unPressed() {
    if (mounted) {
      setState(() {
        _isPressed = false;
      });
    }
  }
}
