import 'package:flutter/material.dart';

class AppTextTheme extends ThemeExtension<AppTextTheme> {
  const AppTextTheme({
    required this.h3Semibold,
    required this.h3Medium,
    required this.title24Medium,
    required this.button18Bold,
    required this.body18Regular,
    required this.body16Semibold,
    required this.body16Medium,
    required this.body16Regular,
    required this.caption14Regular,
  });

  final TextStyle h3Semibold;
  final TextStyle h3Medium;
  final TextStyle title24Medium;
  final TextStyle button18Bold;
  final TextStyle body18Regular;
  final TextStyle body16Semibold;
  final TextStyle body16Medium;
  final TextStyle body16Regular;
  final TextStyle caption14Regular;

  static const _textThemeArchivo = 'Archivo';
  static const _textFontRaleway = 'Raleway';

  //lineheight=fontSize * height so the height values
  //below are the style guide lineheight/fontSize
  static const textTheme = AppTextTheme(
    h3Semibold: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w600,
      fontSize: 28,
      height: 32 / 28,
      letterSpacing: 0.6,
    ),
    h3Medium: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w500,
      fontSize: 28,
      height: 33 / 28,
      letterSpacing: 0.33,
    ),
    title24Medium: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w500,
      fontSize: 24,
      height: 28 / 24,
      letterSpacing: 0.3,
    ),
    button18Bold: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 28 / 20,
      letterSpacing: 0.3,
    ),
    body18Regular: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w400,
      fontSize: 18,
      height: 22 / 18,
      letterSpacing: 0.18,
    ),
    body16Semibold: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 20 / 16,
      letterSpacing: 0.09,
    ),
    body16Medium: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 20 / 16,
      letterSpacing: 0.08,
    ),
    body16Regular: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 20 / 14,
      letterSpacing: 0.51,
    ),
    caption14Regular: TextStyle(
      fontFamily: _textFontRaleway,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 18 / 14,
      letterSpacing: 0.14,
    ),
  );

  @override
  ThemeExtension<AppTextTheme> copyWith({
    TextStyle? h3Semibold,
    TextStyle? h3Medium,
    TextStyle? title24Medium,
    TextStyle? button18Bold,
    TextStyle? body18Regular,
    TextStyle? body16Semibold,
    TextStyle? body16Medium,
    TextStyle? body16Regular,
    TextStyle? caption14Regular,
  }) {
    return AppTextTheme(
      h3Semibold: h3Semibold ?? this.h3Semibold,
      h3Medium: h3Medium ?? this.h3Medium,
      title24Medium: title24Medium ?? this.title24Medium,
      button18Bold: button18Bold ?? this.button18Bold,
      body18Regular: body18Regular ?? this.body18Regular,
      body16Semibold: body16Semibold ?? this.body16Semibold,
      body16Medium: body16Medium ?? this.body16Medium,
      body16Regular: body16Regular ?? this.body16Regular,
      caption14Regular: caption14Regular ?? this.caption14Regular,
    );
  }

  @override
  AppTextTheme lerp(ThemeExtension<AppTextTheme>? other, double t) {
    if (other is! AppTextTheme) {
      return this;
    }
    return AppTextTheme(
      h3Semibold:
          TextStyle.lerp(h3Semibold, other.h3Semibold, t) ??
          textTheme.h3Semibold,
      h3Medium:
          TextStyle.lerp(h3Medium, other.h3Medium, t) ?? textTheme.h3Medium,
      title24Medium:
          TextStyle.lerp(title24Medium, other.title24Medium, t) ??
          textTheme.title24Medium,
      button18Bold:
          TextStyle.lerp(button18Bold, other.button18Bold, t) ??
          textTheme.button18Bold,
      body18Regular:
          TextStyle.lerp(body18Regular, other.body18Regular, t) ??
          textTheme.body18Regular,
      body16Semibold:
          TextStyle.lerp(body16Semibold, other.body16Semibold, t) ??
          textTheme.body16Semibold,
      body16Medium:
          TextStyle.lerp(body16Medium, other.body16Medium, t) ??
          textTheme.body16Medium,
      body16Regular:
          TextStyle.lerp(body16Regular, other.body16Regular, t) ??
          textTheme.body16Regular,
      caption14Regular:
          TextStyle.lerp(caption14Regular, other.caption14Regular, t) ??
          textTheme.caption14Regular,
    );
  }
}
