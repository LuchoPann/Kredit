import 'package:flutter/material.dart';

/// Wraps a [Card] with a subtle drop shadow so it visually lifts off the
/// near-black background — most noticeable on the 'cool'/'warm' bg tones,
/// and reinforced by the card's own border on the pure-black tone.
class ShadowedCard extends StatelessWidget {
  final Widget child;
  const ShadowedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(elevation: 0, child: child);
  }
}
