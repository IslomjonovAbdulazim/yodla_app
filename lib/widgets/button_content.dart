import 'package:flutter/cupertino.dart';
import 'package:yodla_app/widgets/text_styles.dart';

import 'button.dart';

class ButtonContent extends StatelessWidget {
  const ButtonContent({
    super.key,
    required this.widget,
    required bool isPressed,
    required this.loading,
  }) : _isPressed = isPressed;

  final Button widget;
  final bool _isPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ],
        Builder(
          builder: (context) {
            final content = Stack(
              alignment: Alignment.center,
              children: [
                Visibility(
                  visible: !loading,
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  child:
                      widget.child ??
                      Text(
                        widget.text ?? '',
                        style: TextStyles.medium(context).copyWith(
                          color: widget.type.getLabelColor(
                            context,
                            widget,
                            _isPressed,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: CupertinoActivityIndicator(
                      color: widget.type.getLabelColor(
                        context,
                        widget,
                        _isPressed,
                      ),
                    ),
                  ),
              ],
            );
            if (!widget.expanded) return content;
            return Expanded(child: content);
          },
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          widget.trailing!,
        ],
      ],
    );
  }
}
