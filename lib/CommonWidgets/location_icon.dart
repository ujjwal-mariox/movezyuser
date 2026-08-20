import 'package:flutter/material.dart';

/// The app's icon size ladder.
///
/// Sizes used to be hand-written at every call site, so the same glyph in the
/// same role rendered at 12/13/14/15 or 17/18/19/21 depending on the screen —
/// 30 distinct values across the app, several of them 1px apart. Every
/// explicit `Icon(size:)` now sits on this ladder; use these constants for new
/// work instead of a raw number.
///
/// (Sizes below 12 are deliberately off the ladder: route bullets and status
/// dots at 6-9px are micro-glyphs, and rounding them up would double them.)
abstract final class AppIconSize {
  /// Inline with body text (trailing chevrons, small affordances).
  static const double xs = 12;
  static const double sm = 16;

  /// Default for list rows, app-bar actions, address rows.
  static const double md = 20;

  /// Pickup/drop location markers and primary row icons.
  static const double lg = 22;
  static const double xxl = 24;

  /// Feature/section headers.
  static const double xl = 28;
  static const double headerLg = 32;

  /// Empty states and hero illustrations.
  static const double display = 40;
  static const double displayLg = 48;
  static const double hero = 56;
  static const double heroLg = 64;
}

/// The pickup / drop marker pair, from the design assets.
///
/// Every screen that shows an address pair renders this, so the glyphs and
/// their size cannot drift apart again. Before this, the same pair appeared as
/// the design PNGs on some screens, `Icons.circle` + `Icons.location_on` on the
/// review page, `Icons.trip_origin` + `Icons.location_on` on live tracking, and
/// a bare green `Container` + `clip_path.png` on trip details — four different
/// treatments of one concept, at four different sizes.
class LocationIcon extends StatelessWidget {
  final bool isPickup;
  final double size;

  const LocationIcon.pickup({super.key, this.size = AppIconSize.lg})
      : isPickup = true;

  const LocationIcon.drop({super.key, this.size = AppIconSize.lg})
      : isPickup = false;

  /// For call sites that decide pickup/drop at runtime.
  const LocationIcon({super.key, required this.isPickup, this.size = AppIconSize.lg});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isPickup ? 'assets/pic_up_location.png' : 'assets/drop_up_location.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// The white rounded tile that holds a location glyph beside an address input.
///
/// Exists because of a constraint trap that made "the same 22px icon" render
/// at three different sizes: `Container(width: 45/46, height: ...)` passes
/// TIGHT constraints to its child, and a tight constraint overrides whatever
/// width/height the child declares. So SearchScreen's icon really rendered at
/// 33px (45 − 2×6 padding), VehicleSelection's at 24px (46 − 2×11), and an
/// intermediate-stop `Icon` with no padding at all filled the whole 46px tile.
/// The declared 22 was dead code everywhere.
///
/// `alignment:` wraps the child in an `Align`, which passes LOOSE constraints
/// — the child's own size finally wins. Every address-input tile must render
/// through this widget so no call site can reintroduce the override.
class LocationTile extends StatelessWidget {
  final Widget child;
  final double size;

  const LocationTile({super.key, required this.child, this.size = 45});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
