import 'package:flutter/material.dart';

enum ButtonType { filled, text }

class Button extends StatefulWidget {
  final ButtonType type;

  final Widget child;

  final void Function()? onPressed;

  final bool isLoading;

  const Button({
    super.key,
    required this.type,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  });

  const Button.filled({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  }) : type = ButtonType.filled;

  const Button.text({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  }) : type = ButtonType.text;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  Widget _buildCircularProgressIndicator(ButtonType type) {
    final Size size = switch (type) {
      ButtonType.filled => const Size(24, 24),
      ButtonType.text => const Size(14, 14),
    };
    return Builder(
      builder: (context) {
        final textColor = DefaultTextStyle.of(context).style.color;
        return CircularProgressIndicator(
          constraints: BoxConstraints.tight(size),
          strokeWidth: 2,
          color: textColor,
        );
      },
    );
  }

  Widget buildButton() {
    return switch (widget.type) {
      ButtonType.filled => FilledButton(
        onPressed: widget.isLoading ? () {} : widget.onPressed,
        child:
            widget.isLoading
                ? _buildCircularProgressIndicator(widget.type)
                : widget.child,
      ),
      ButtonType.text => TextButton(
        onPressed: widget.isLoading ? () {} : widget.onPressed,
        child:
            widget.isLoading
                ? _buildCircularProgressIndicator(widget.type)
                : widget.child,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return buildButton();
  }
}
