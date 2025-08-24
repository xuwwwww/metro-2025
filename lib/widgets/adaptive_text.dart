import 'package:flutter/material.dart';
import '../utils/font_size_manager.dart';

/// 自適應文字組件，會根據全局字體大小自動調整
class AdaptiveText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSizeMultiplier;
  final Color? color;
  final FontWeight? fontWeight;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSizeMultiplier,
    this.color,
    this.fontWeight,
  });

  @override
  State<AdaptiveText> createState() => _AdaptiveTextState();
}

class _AdaptiveTextState extends State<AdaptiveText> {
  double _currentFontSize = FontSizeManager.fontSize;

  @override
  void initState() {
    super.initState();
    FontSizeManager.addListener(_onFontSizeChanged);
  }

  @override
  void dispose() {
    FontSizeManager.removeListener(_onFontSizeChanged);
    super.dispose();
  }

  void _onFontSizeChanged(double newFontSize) {
    setState(() {
      _currentFontSize = newFontSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = widget.fontSizeMultiplier ?? 1.0;
    final baseFontSize = _currentFontSize * multiplier;

    final textStyle = (widget.style ?? const TextStyle()).copyWith(
      fontSize: baseFontSize,
      color: widget.color ?? widget.style?.color,
      fontWeight: widget.fontWeight ?? widget.style?.fontWeight,
    );

    return Text(
      widget.text,
      style: textStyle,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// 自適應標題文字
class AdaptiveTitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const AdaptiveTitle(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AdaptiveText(
      text,
      fontSizeMultiplier: 1.75, // 標題字體大小
      color: color ?? Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
      textAlign: textAlign,
    );
  }
}

/// 自適應副標題文字
class AdaptiveSubtitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const AdaptiveSubtitle(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AdaptiveText(
      text,
      fontSizeMultiplier: 1.25, // 副標題字體大小
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.w500,
      textAlign: textAlign,
    );
  }
}

/// 自適應正文文字
class AdaptiveBodyText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveBodyText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveText(
      text,
      fontSizeMultiplier: 1.0, // 正文字體大小
      color: color ?? Theme.of(context).colorScheme.onSurface,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 自適應小字體文字
class AdaptiveSmallText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const AdaptiveSmallText(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AdaptiveText(
      text,
      fontSizeMultiplier: 0.875, // 小字體大小
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      textAlign: textAlign,
    );
  }
}
