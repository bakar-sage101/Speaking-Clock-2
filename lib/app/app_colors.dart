part of '../main.dart';

/// Lumen palette. Colours resolve against [brightness], which the app sets from
/// the user's light/dark preference before each build. Every legacy token name
/// is kept so the whole app reads from one place.
class AppColors {
  /// Set by the root before building the widget tree.
  static Brightness brightness = Brightness.dark;
  static bool get _l => brightness == Brightness.light;

  // Grounds & ink
  // Light: warm linen ground, cream surfaces, warm near-black ink.
  static Color get ink => _l ? const Color(0xffECE3D3) : const Color(0xff0E1015);
  static Color get ink2 => _l ? const Color(0xffE3D8C6) : const Color(0xff0A0C10);
  static Color get surface => _l ? const Color(0xffF6F0E3) : const Color(0xff14161C);
  static Color get surfaceRaised => _l ? const Color(0xffEDE3D2) : const Color(0xff20242D);
  static Color get bone => _l ? const Color(0xff2A2621) : const Color(0xffECEAE3);
  static Color get boneDim => _l ? const Color(0xff8A8073) : const Color(0x9EEDEBE4);
  static Color get line => _l ? const Color(0x14332815) : const Color(0x17FFFFFF);
  static Color get line2 => _l ? const Color(0x28332815) : const Color(0x28FFFFFF);
  static Color get glass => _l ? const Color(0x0A332815) : const Color(0x0AFFFFFF);

  // Identity accent — brass in dark, olive green in light.
  static Color get brass => _l ? const Color(0xff6F7E2C) : const Color(0xffDCB65E);
  static Color get brassDim => _l ? const Color(0xff55621F) : const Color(0xffB4842B);

  // Intensity triad — light: olive / terracotta / purple (warm direction).
  static Color get gentle => _l ? const Color(0xff6E7E2E) : const Color(0xff4FD1BE);
  static Color get alarm => _l ? const Color(0xffB65A3F) : const Color(0xffF0735A);
  static Color get speaking => _l ? const Color(0xff35636E) : const Color(0xffA588E6);
  static Color get destructive => alarm;

  // Wine — a subtle personality accent for eyebrows and section labels.
  static Color get wine => _l ? const Color(0xff8C4E5C) : const Color(0xffC98BA0);
  // Blush — warm atmosphere glow behind the Today clock (light only).
  static Color get blush => _l ? const Color(0xffE7B9C4) : const Color(0xffE85A9B);

  // Legacy aura hues + semantic aliases → mapped onto the palette.
  static Color get auraMagenta => speaking;
  static Color get auraBlue => brass;
  static Color get auraCoral => alarm;
  static Color get auraLime => gentle;
  static Color get linen => bone;
  static Color get darkWine => bone;
  static Color get mutedWine => alarm;
  static Color get ashGrey => boneDim;
  static Color get brightSnow => surfaceRaised;
  static Color get periwinkleMist => brass;
  static Color get canvas => ink;
  static Color get sage => gentle;
  static Color get sageLight => surface;
  static Color get blue => gentle;
  static Color get amber => alarm;
  static Color get amberLight => surfaceRaised;

  // Foreground for filled brass surfaces (dark text on gold, both themes).
  static const onBrass = Color(0xff1A1205);

  static Gradient get onboardingGradient => RadialGradient(
    center: const Alignment(0.0, -0.2),
    radius: 1.2,
    colors: [speaking, speaking.withValues(alpha: 0.4), Colors.transparent],
    stops: const [0.0, 0.34, 0.72],
  );

  static Gradient get heroGradient => const RadialGradient(
    center: Alignment(-0.2, 0.0),
    radius: 1.0,
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF), Colors.transparent],
    stops: [0.0, 0.52, 1.0],
  );

  static Gradient get wineHeroGradient => RadialGradient(
    center: const Alignment(-0.1, 0.05),
    radius: 1.1,
    colors: [speaking, speaking.withValues(alpha: 0.4), Colors.transparent],
    stops: const [0.0, 0.36, 0.78],
  );

  static Gradient get softCardGradient => const RadialGradient(
    center: Alignment(-0.8, -0.7),
    radius: 1.4,
    colors: [Color(0x12FFFFFF), Color(0x05FFFFFF), Colors.transparent],
    stops: [0.0, 0.42, 1.0],
  );

  static Gradient get signatureHeroGradient => wineHeroGradient;
}
