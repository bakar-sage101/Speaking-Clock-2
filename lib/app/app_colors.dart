part of '../main.dart';

class AppColors {
  static const linen = Color(0xfff0e5de);
  static const darkWine = Color(0xff6f1d1b);
  static const mutedWine = Color(0xff8a3632);
  static const ashGrey = Color(0xffabbdab);
  static const brightSnow = Color(0xfffafbfd);
  static const blush = Color(0xffe7c9c4);
  static const periwinkleMist = Color(0xffbfb4dc);
  static const canvas = Color(0xfff8f1ec);
  static const ink = Color(0xff28342b);
  static const sage = ashGrey;
  static const sageLight = Color(0xffe7eee5);
  static const blue = Color(0xff8aa9ad);
  static const amber = mutedWine;
  static const amberLight = Color(0xfff3ded8);
  static const line = Color(0xffe6d9d2);

  static const onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkWine, blush, linen, ashGrey],
    stops: [0.0, 0.28, 0.68, 1.0],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brightSnow, linen, sageLight],
  );

  static const wineHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkWine, mutedWine, blush],
  );

  static const softCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brightSnow, canvas],
  );
}
