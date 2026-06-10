import 'package:flutter/material.dart';

class CustomUnderlineText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isBoldLine;

  const CustomUnderlineText(this.text,
      {Key? key, this.style, this.isBoldLine = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Text(text, style: style),
        Positioned(
            bottom: isBoldLine ? -1.5 : (style?.height ?? 0),
            left: 0,
            right: 0,
            child: Container(
              height: isBoldLine ? 1.5 : 1,
              color: style?.color,
            )),
      ],
    );
  }
}
