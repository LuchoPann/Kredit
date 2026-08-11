import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// App wordmark ("K"), swapping fill color for light/dark mode.
/// Assets ported from legacy_pwa/icons/KREDIT.svg (dark-mode/white variant)
/// with a generated light-mode/black variant at assets/brand/.
class KreditLogo extends StatelessWidget {
  final double height;

  const KreditLogo({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/brand/kredit_logo_dark.svg'
        : 'assets/brand/kredit_logo_light.svg';
    return SvgPicture.asset(asset, height: height);
  }
}
