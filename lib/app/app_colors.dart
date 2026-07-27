part of '../main.dart';

/// Lumen palette — graphite ground, brass identity accent, and a functional
/// intensity triad (teal / coral / iris). Every legacy token name from the
/// earlier "Aura on Ink" system is kept as an alias so the whole app keeps
/// compiling while screens are migrated one at a time.
class AppColors {
  // Grounds & ink (dark-first)
  static const ink = Color(0xff0E1015); // canvas / ground
  static const ink2 = Color(0xff0A0C10);
  static const surface = Color(0xff14161C); // raised card
  static const surfaceRaised = Color(0xff20242D);
  static const bone = Color(0xffECEAE3); // warm lume white
  static const boneDim = Color(0x9EEDEBE4);
  static const line = Color(0x17FFFFFF); // hairline
  static const line2 = Color(0x28FFFFFF);
  static const glass = Color(0x0AFFFFFF);

  // Identity accent — brass (reserved for time: indices, hands, selected value)
  static const brass = Color(0xffDCB65E);
  static const brassDim = Color(0xffB4842B);

  // Intensity triad (meaning only, never decoration)
  static const gentle = Color(0xff4FD1BE); // teal
  static const alarm = Color(0xffF0735A); // coral
  static const speaking = Color(0xffA588E6); // iris
  static const destructive = Color(0xffF0735A);

  // Legacy aura hues remapped onto the new triad + brass.
  static const auraMagenta = speaking;
  static const auraBlue = brass;
  static const auraCoral = alarm;
  static const auraLime = gentle;

  // Legacy semantic aliases kept so existing screens migrate safely.
  static const linen = bone;
  static const darkWine = bone;
  static const mutedWine = alarm;
  static const ashGrey = boneDim;
  static const brightSnow = surfaceRaised;
  static const blush = speaking;
  static const periwinkleMist = brass;
  static const canvas = ink;
  static const sage = gentle;
  static const sageLight = surface;
  static const blue = gentle;
  static const amber = alarm;
  static const amberLight = surfaceRaised;

  static const onboardingGradient = RadialGradient(
    center: Alignment(0.0, -0.2),
    radius: 1.2,
    colors: [speaking, Color(0x66A588E6), Colors.transparent],
    stops: [0.0, 0.34, 0.72],
  );

  static const heroGradient = RadialGradient(
    center: Alignment(-0.2, 0.0),
    radius: 1.0,
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF), Colors.transparent],
    stops: [0.0, 0.52, 1.0],
  );

  static const wineHeroGradient = RadialGradient(
    center: Alignment(-0.1, 0.05),
    radius: 1.1,
    colors: [speaking, Color(0x66A588E6), Colors.transparent],
    stops: [0.0, 0.36, 0.78],
  );

  static const softCardGradient = RadialGradient(
    center: Alignment(-0.8, -0.7),
    radius: 1.4,
    colors: [Color(0x12FFFFFF), Color(0x05FFFFFF), Colors.transparent],
    stops: [0.0, 0.42, 1.0],
  );

  static const signatureHeroGradient = RadialGradient(
    center: Alignment(-0.2, 0.1),
    radius: 1.15,
    colors: [speaking, Color(0x66A588E6), Colors.transparent],
    stops: [0.0, 0.36, 0.78],
  );
}
