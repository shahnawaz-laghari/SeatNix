import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';

import '../services/language.dart';

export '../services/language.dart' show tr;

/// Drop-in replacement for [m.Text] that translates its text when Urdu is
/// selected. Import this file with `hide Text` on the Material import.
class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return m.Text(
      tr(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
