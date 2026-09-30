import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_parsing/path_parsing.dart';

import '../providers/credits_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/wallet_card.dart' show prewarmCardCaches;

// ─── Reveal direction per stroke ─────────────────────────────────────────────

enum _RevealDir { bottomTop, topBottom, leftRight, rightLeft }

// ─── Segment: parsed Path + bounding box + animation timing ──────────────────

class _Segment {
  final Path path;
  final Rect bounds;
  final _RevealDir dir;
  final double t0; // animation start (0–1 of controller)
  final double t1; // animation end   (0–1 of controller)

  const _Segment(this.path, this.bounds, this.dir, this.t0, this.t1);
}

// ─── SVG path strings + animation metadata ───────────────────────────────────
//
// Order: K (stem, upper arm, lower arm) → R (body, leg) → E (top, top-right,
// middle, btm-left, btm-right) → D (left, right) → I (stem) → T (bar-left,
// bar-right, stem).
//
// t0/t1 create the left-to-right stagger: later letters start later.
// Each segment reveals in 22 % of the timeline so any two consecutive segments
// overlap slightly, giving a fluid continuous feel.

typedef _Def = ({String d, _RevealDir dir, double t0, double t1});

const List<_Def> _segDefs = [
  // ── K stem (vertical upper half, bottomTop) ──────────────────────────────
  (
    d: 'M4.10 155.25 l-1.10 -1.40 0 -70.60 c0 -79.40 -0.30 -73.60 3.75 -77.15'
        ' 1.20 -1.05 3.05 -2.20 4.15 -2.50 3 -0.90 52.70 -0.80 55.25 0.10'
        ' 2.85 1.05 5.10 3 6.30 5.50 1.05 2.30 1.05 2.35 1.05 48.25'
        ' 0 39.50 -0.10 46.20 -0.75 47.70 -0.60 1.40 -3.10 3.60 -11.85 10.25'
        ' -13.30 10.15 -31.45 24.25 -47.10 36.50 -6.20 4.85 -8 5.50 -9.70 3.35z',
    dir: _RevealDir.bottomTop,
    t0: 0.00,
    t1: 0.22,
  ),
  // ── K upper diagonal arm (leftRight) ─────────────────────────────────────
  (
    d: 'M141.55 149.95 c-0.65 -0.25 -4.75 -3.55 -9.20 -7.35'
        ' -4.40 -3.75 -9.85 -8.40 -12.10 -10.35 -2.25 -1.90 -6.30 -5.30 -9.05 -7.50'
        ' -2.70 -2.20 -6 -5.05 -7.30 -6.30 -2.15 -2.05 -2.40 -2.55 -2.40 -4.50'
        ' 0 -3 1.05 -4.50 6.30 -9.20 2.45 -2.20 7.05 -6.35 10.20 -9.30'
        ' 3.15 -2.90 9.35 -8.55 13.80 -12.50 4.40 -3.95 11.70 -10.55 16.20 -14.70'
        ' 4.50 -4.10 10.45 -9.50 13.25 -12 2.80 -2.45 10.25 -9.10 16.55 -14.75'
        ' 6.30 -5.60 16.75 -14.95 23.20 -20.70 6.45 -5.75 13.05 -11.70 14.65 -13.15'
        ' 5.55 -5.05 1.75 -4.65 42.90 -4.65 l36.05 0 1.70 1.70'
        ' c2.15 2.15 2.25 4.20 0.35 6.25 -0.80 0.80 -4.10 3.90 -7.40 6.85'
        ' -7.85 7 -14.70 13.30 -21.15 19.35 -2.85 2.70 -7.55 7 -10.45 9.65'
        ' -2.90 2.60 -10.10 9.30 -16.05 14.85'
        ' -14.25 13.35 -30.85 28.80 -35.35 32.85'
        ' -5.55 5 -37.25 34.65 -48.35 45.15 -11.15 10.60 -12.90 11.70 -16.35 10.30z',
    dir: _RevealDir.leftRight,
    t0: 0.04,
    t1: 0.24,
  ),
  // ── K lower diagonal (bottomTop — sweep upward across the chevron) ────────
  (
    d: 'M10.55 305.30 c-2.90 -1.05 -5.40 -3.55 -6.50 -6.55'
        ' -1.05 -2.75 -1.05 -3.40 -1.05 -54.75 0 -35.40 0.15 -52.40 0.55 -53.35'
        ' 0.25 -0.75 1.25 -2.15 2.10 -3.10 1.45 -1.50 12.80 -11.20 22.60 -19.30'
        ' 2 -1.65 6.95 -5.80 11.05 -9.20 27.90 -23.35 35.15 -29.25 37.35 -30.40'
        ' 2.75 -1.50 7.85 -1.60 10.15 -0.20 0.85 0.50 5.35 4.05 9.95 7.90'
        ' 4.65 3.80 11.05 9.05 14.25 11.65 3.20 2.60 7.80 6.45 10.30 8.60'
        ' 2.45 2.10 6.15 5.20 8.20 6.90 2.05 1.65 6.55 5.40 10 8.25'
        ' 3.45 2.85 9.75 8.10 14 11.60 11.75 9.75 46.50 38.85 59.20 49.65'
        ' 2.45 2.05 6.05 5.10 8.05 6.75 3.60 3 14.45 12.35 23 19.75'
        ' 2.50 2.15 8.35 7.20 13 11.25 35.55 30.60 32.25 27.60 32.25 29.70'
        ' 0 2.40 -1.65 4.20 -4.65 5 -1.55 0.45 -11.55 0.55 -37.60 0.45'
        ' -40.85 -0.15 -36.60 0.35 -43 -5.50'
        ' -4.55 -4.15 -16.45 -14.60 -30.95 -27.10'
        ' -6.35 -5.45 -13.35 -11.55 -15.55 -13.50 -2.20 -2 -8.95 -7.85 -15 -13.05'
        ' -6.05 -5.20 -13.35 -11.50 -16.20 -14 -2.85 -2.45 -8.05 -6.95 -11.55 -10'
        ' -3.50 -3 -11.80 -10.20 -18.50 -16 -17.75 -15.40 -20.65 -17.75 -21.60 -17.75'
        ' -0.85 0 -0.90 2.80 -1 54.95 l-0.15 54.95 -1.50 2.15'
        ' c-0.95 1.35 -2.50 2.70 -4.20 3.55 l-2.65 1.40'
        ' -26.35 -0.05 c-19.30 0 -26.75 -0.20 -28 -0.65z',
    dir: _RevealDir.bottomTop,
    t0: 0.06,
    t1: 0.28,
  ),
  // ── R body (vertical, bottomTop) ─────────────────────────────────────────
  (
    d: 'M339.20 305.30 c-2.70 -1.25 -4.70 -3.45 -5.65 -6.25'
        ' -0.40 -1.25 -0.55 -23.20 -0.55 -81.55 l0 -79.85 1.05 -0.95'
        ' c1.05 -0.95 3.50 -0.95 103.65 -1 101.90 -0.05 102.55 -0.05 105.70 -1.10'
        ' 4.45 -1.45 7.05 -3.10 10.20 -6.55 3.30 -3.50 5.60 -8.55 6.45 -14.10'
        ' 0.35 -2.35 0.50 -7 0.30 -12.95 -0.25 -8.20 -0.40 -9.65 -1.50 -12.70'
        ' -2.25 -6.20 -5.95 -10.35 -11.85 -13.30'
        ' -5.10 -2.60 -0.20 -2.50 -106.25 -2.50'
        ' -95.35 0 -99.05 -0.05 -101 -0.95 -2.65 -1.25 -5.05 -3.80 -6 -6.50'
        ' -1.15 -3.25 -1.15 -51.15 0.05 -53.95 0.95 -2.40 2.95 -4.40 5.45 -5.70'
        ' 1.95 -1.05 2.35 -1.05 111.50 -1.25 76.90 -0.15 111 -0.05 114.60 0.35'
        ' 10.55 1.10 20 3.70 27.70 7.65 6.45 3.25 9.75 5.45 14.10 9.30'
        ' 12.55 11.20 19.75 24.70 22.60 42.40 0.60 3.75 0.75 10.70 0.75 36.80'
        ' 0 32.75 -0.15 36.40 -2.05 45.45 -1.35 6.50 -2.35 9.30 -5.75 15.95'
        ' -3.75 7.30 -7.70 12.50 -13.35 17.55 -8.40 7.40 -15.50 11.45 -25.95 14.60'
        ' -12.10 3.65 -7.65 3.50 -95 3.65 l-78.40 0.20 0 49.40'
        ' c0 54.05 0.10 52.05 -2.90 55.20 -0.75 0.80 -2.25 1.95 -3.35 2.50'
        ' -2 1.10 -2.35 1.10 -32 1.25 l-30 0.10 -2.55 -1.20z',
    dir: _RevealDir.bottomTop,
    t0: 0.20,
    t1: 0.42,
  ),
  // ── R diagonal leg (leftRight) ────────────────────────────────────────────
  (
    d: 'M540.65 306 c-2.10 -0.50 -3.65 -1.50 -7.40 -4.95'
        ' -1.70 -1.55 -5.95 -5.40 -9.50 -8.55'
        ' -11.75 -10.50 -43.25 -39.10 -48.50 -44'
        ' -1.90 -1.85 -5.30 -4.85 -7.50 -6.80 -2.20 -1.90 -7.50 -6.60 -11.75 -10.45'
        ' -4.25 -3.85 -9.50 -8.55 -11.60 -10.40 -3.75 -3.30 -3.90 -3.50 -3.90 -5.65'
        ' 0 -1.80 0.20 -2.30 1.35 -3.05 1.25 -0.85 3.95 -0.90 41.90 -0.90'
        ' 36.70 0 40.65 0.10 42 0.80 1.50 0.85 5.15 3.95 20.25 17.45'
        ' 4.50 4 9.20 8.15 10.50 9.25 2.85 2.45 18.55 16.25 30.45 26.80'
        ' 4.85 4.25 11.40 10 14.55 12.75 17.75 15.25 23.90 20.75 24.20 21.45'
        ' 0.85 2.30 -0.45 4.60 -3.55 6.20 -1.25 0.65 -78.80 0.70 -81.50 0.05z',
    dir: _RevealDir.leftRight,
    t0: 0.26,
    t1: 0.46,
  ),
  // ── E top bar (leftRight) ─────────────────────────────────────────────────
  (
    d: 'M681.65 68.50 c-3.95 -0.40 -7 -3.20 -8.15 -7.55'
        ' -0.35 -1.25 -0.50 -10.30 -0.40 -25.30 l0.15 -23.40 1.25 -2.25'
        ' c0.70 -1.20 2.25 -2.90 3.40 -3.75 l2.20 -1.50'
        ' 81.05 -0.15 c60.55 -0.10 81.80 0 83.80 0.45'
        ' 3.30 0.70 1.70 -0.80 36.20 33.10 24 23.60 24.85 24.50 24.85 26.30'
        ' 0 1.30 -0.35 2.20 -1.15 2.95 l-1.15 1.10'
        ' -109.75 0.10 c-60.30 0.10 -110.85 0.05 -112.30 -0.10z',
    dir: _RevealDir.leftRight,
    t0: 0.38,
    t1: 0.56,
  ),
  // ── E top-right corner block (leftRight) ──────────────────────────────────
  (
    d: 'M934 68.70 c-1.10 -0.45 -12.50 -11.50 -30.35 -29.35'
        ' -28.50 -28.45 -28.65 -28.60 -28.65 -30.65 0 -1.55 0.30 -2.30 1.30 -3.25'
        ' l1.30 -1.20 59 0.15 c56.35 0.15 59.10 0.20 60.85 1.05'
        ' 2.05 1.10 3.10 2.15 4.25 4.40 0.70 1.40 0.80 4.55 0.80 26.75'
        ' 0 25.15 0 25.15 -1.15 27.15 -0.60 1.05 -2.05 2.65 -3.20 3.45'
        ' -1.95 1.35 -2.65 1.50 -7.75 1.85'
        ' -3.10 0.20 -16.65 0.40 -30.15 0.40 -20.95 0 -24.75 -0.10 -26.25 -0.75z',
    dir: _RevealDir.leftRight,
    t0: 0.40,
    t1: 0.58,
  ),
  // ── E middle bar (leftRight) ──────────────────────────────────────────────
  (
    d: 'M679.50 186.70 c-0.95 -0.40 -2.40 -1.35 -3.15 -2.10'
        ' -2.85 -2.70 -2.85 -2.45 -2.85 -30.45 l0 -25.70 1.25 -2.45'
        ' c0.80 -1.60 2.05 -3 3.35 -3.85 l2.10 -1.40'
        ' 123.75 -0.15 c68.10 -0.05 124.55 0 125.45 0.15'
        ' 2.10 0.40 5 2.95 6.15 5.50 0.85 1.85 0.95 3.90 0.95 27.75'
        ' 0 24 -0.10 25.90 -0.95 27.75 -1.20 2.55 -2.80 4.05 -5.50 5'
        ' -1.95 0.65 -15.90 0.75 -125.50 0.75'
        ' -109.05 -0.05 -123.50 -0.15 -125.05 -0.80z',
    dir: _RevealDir.leftRight,
    t0: 0.42,
    t1: 0.60,
  ),
  // ── E bottom-left section (leftRight) ────────────────────────────────────
  (
    d: 'M678.25 303.80 c-3 -1.40 -4.35 -2.80 -5.70 -5.80'
        ' -1 -2.15 -1.05 -3.15 -1.05 -29.05 l0 -26.75 1.30 -2.60'
        ' c1.50 -3.05 4 -5.25 7.15 -6.35 2.50 -0.85 18.95 -0.95 51.30 -0.30'
        ' 14.20 0.30 17.85 0.50 19.25 1.15'
        ' 1.85 0.80 62.40 61.15 64.15 63.95 1.25 1.90 0.85 4.80 -0.75 6.05'
        ' -1.10 0.85 -5.05 0.90 -67.15 0.90 l-66 0 -2.50 -1.20z',
    dir: _RevealDir.leftRight,
    t0: 0.44,
    t1: 0.62,
  ),
  // ── E bottom-right section (leftRight) ────────────────────────────────────
  (
    d: 'M846.45 303.80 c-2.90 -0.75 -3.25 -1.05 -11.70 -9.80'
        ' -3.85 -3.95 -11.80 -12.05 -17.70 -18'
        ' -5.85 -5.90 -16.40 -16.55 -23.40 -23.60 l-12.80 -12.90'
        ' 0.25 -2.55 c0.30 -3.05 1.50 -4.25 4.65 -4.70'
        ' 1.10 -0.15 47.90 -0.25 104 -0.15 l102 0.15'
        ' 2.10 1.10 c1.10 0.60 2.75 1.95 3.60 3'
        ' 3.05 3.70 3.05 3.80 3.05 31.90 0 22.50 -0.10 25.85 -0.85 28.05'
        ' -1.10 3.35 -2.80 5.40 -5.30 6.60'
        ' -2.05 0.95 -3.90 1 -73.85 1.25 -56.10 0.20 -72.25 0.15 -74.05 -0.35z',
    dir: _RevealDir.leftRight,
    t0: 0.46,
    t1: 0.64,
  ),
  // ── D left / diagonal top (bottomTop) ────────────────────────────────────
  (
    d: 'M1042.95 296.25 c-0.75 -0.40 -1.60 -1.45 -1.90 -2.30'
        ' -0.40 -1.15 -0.55 -40.65 -0.55 -141.90'
        ' 0.05 -115.90 0.15 -140.65 0.70 -142.20'
        ' 1.05 -2.90 3.10 -5.25 5.95 -6.70 l2.60 -1.35'
        ' 112.15 -0.20 c116.75 -0.20 123.85 -0.10 133.85 1.90'
        ' 5.95 1.20 7.45 2.10 7.65 4.70 0.15 1.70 -0.10 2.05 -2.70 4.45'
        ' -1.60 1.45 -6.60 6.10 -11.15 10.35 -4.60 4.25 -14.50 13.55 -22.05 20.60'
        ' -7.55 7.05 -16.40 15.30 -19.60 18.35 -5.05 4.75 -6.25 5.60 -8.50 6.25'
        ' -2.20 0.60 -10.15 0.75 -44.90 1'
        ' -23.25 0.20 -50.05 0.30 -59.55 0.35 -9.50 0 -17.75 0.15 -18.35 0.30'
        ' l-1.10 0.25 0 79.40 0 79.35 -1.50 3'
        ' c-0.85 1.75 -2.55 4 -3.90 5.20 -1.30 1.15 -9.65 9.20 -18.60 17.90'
        ' -30.65 29.80 -42.50 40.90 -44.25 41.55 -1.75 0.65 -2.75 0.60 -4.30 -0.25z',
    dir: _RevealDir.bottomTop,
    t0: 0.58,
    t1: 0.78,
  ),
  // ── D right curve (bottomTop) ─────────────────────────────────────────────
  (
    d: 'M1068.35 304.95 c-1 -0.75 -1.35 -1.45 -1.35 -2.80'
        ' 0 -1.55 0.50 -2.30 3.90 -5.65 11.25 -11.25 61.55 -59.90 62.85 -60.80'
        ' 3.25 -2.20 2.70 -2.20 65.60 -2.20 58.15 0 60.10 -0.05 63.85 -1'
        ' 5.15 -1.30 8.30 -3.10 12.40 -6.95 4.05 -3.80 7.10 -9.40 7.85 -14.45'
        ' 0.30 -1.95 0.40 -24.45 0.25 -59.50 -0.25 -61.55 -0.10 -58.50 -3.20 -64.55'
        ' -2.85 -5.65 -7.80 -9.90 -14.35 -12.35 -3.80 -1.40 -4.65 -2.20 -4.65 -4.35'
        ' 0 -1.65 0.80 -2.50 10.50 -11.30 6.70 -6.05 30.75 -28.50 40.25 -37.50'
        ' 3.55 -3.40 7.25 -6.50 8.15 -6.90 1.55 -0.65 1.90 -0.60 4.45 0.55'
        ' 6.25 2.90 16.85 12.80 22.45 21.05 5.70 8.35 9.25 16.55 12.05 27.60'
        ' l1.40 5.40 0 83.75 c0 89.70 0.05 86.90 -2.55 96.75'
        ' -1.45 5.65 -4.65 13.55 -7.15 17.75 -2.95 4.95 -9.10 12.90 -12.65 16.35'
        ' -7.30 7.10 -21.10 15.25 -31.40 18.55'
        ' -11.25 3.60 -1.25 3.30 -125.55 3.50 l-111.80 0.10 -1.30 -1.05z',
    dir: _RevealDir.bottomTop,
    t0: 0.62,
    t1: 0.82,
  ),
  // ── I vertical stem (bottomTop) ───────────────────────────────────────────
  (
    d: 'M1412.60 305.05 c-3.20 -1.10 -5.35 -3.05 -6.80 -6.05'
        ' l-1.05 -2.25 -0.15 -141 c-0.10 -105.30 0 -141.70 0.40 -143.70'
        ' 0.45 -2 1.15 -3.25 2.70 -4.95 3.90 -4.25 2.60 -4.10 34.30 -4.10'
        ' 26.25 0 28.05 0.05 30.10 0.95 2.60 1.15 5.05 3.60 6.10 6.15'
        ' 0.70 1.65 0.80 16.65 0.80 143.30 0 158.65 0.35 144.80 -3.75 148.85'
        ' -3.75 3.75 -3.65 3.75 -33.70 3.75 -24.15 -0.05 -26.50 -0.10 -28.95 -0.95z',
    dir: _RevealDir.bottomTop,
    t0: 0.76,
    t1: 0.92,
  ),
  // ── T top bar left section (leftRight) ───────────────────────────────────
  (
    d: 'M1521.30 69.25 c-2.35 -0.80 -4.55 -2.85 -5.85 -5.35'
        ' -0.90 -1.75 -0.95 -3.25 -0.95 -27 0 -25.15 0 -25.20 1.15 -27.40'
        ' 0.75 -1.55 1.85 -2.70 3.55 -3.75 l2.45 -1.50'
        ' 90.90 -0.15 c86.05 -0.10 90.90 -0.05 91.90 0.75'
        ' 0.60 0.50 1.20 1.75 1.40 2.80 0.25 1.80 0.15 2 -2.65 4.75'
        ' -1.65 1.60 -15.30 14.90 -30.45 29.65'
        ' -23 22.35 -27.85 26.80 -29.55 27.35 -3.20 0.95 -119.20 0.85 -121.90 -0.15z',
    dir: _RevealDir.leftRight,
    t0: 0.82,
    t1: 0.96,
  ),
  // ── T top bar right section (leftRight) ──────────────────────────────────
  (
    d: 'M1690.70 62.40 c-7.65 -7.60 -7.70 -7.65 -7.70 -9.90'
        ' l0 -2.25 9.40 -9.25 c23 -22.70 36.35 -35.15 38.85 -36.30'
        ' l2.50 -1.20 38.75 0 c23.60 0 39.45 0.20 40.50 0.50'
        ' 2.45 0.65 5.45 3.30 6.55 5.70 0.85 1.90 0.95 3.80 0.95 27.05'
        ' 0 23.10 -0.10 25.15 -0.95 27 -1.15 2.55 -3.95 5.05 -6.40 5.70'
        ' -1.30 0.35 -20.50 0.55 -58.35 0.55 l-56.40 0 -7.70 -7.60z',
    dir: _RevealDir.leftRight,
    t0: 0.86,
    t1: 1.00,
  ),
  // ── T vertical stem (bottomTop) ───────────────────────────────────────────
  (
    d: 'M1632.40 305.50 c-4.05 -1.20 -6.95 -4 -8.30 -7.95'
        ' -0.45 -1.25 -0.60 -25.05 -0.60 -94.95'
        ' 0 -87.45 0.05 -93.45 0.90 -96.05 1 -3.25 0.15 -2.35 18.35 -19.60'
        ' 15.80 -15 22.50 -21.05 23.65 -21.55 0.45 -0.20 2.30 -0.35 4.10 -0.35'
        ' l3.20 -0.05 11.65 11.60 c8.85 8.85 11.80 12.05 12.15 13.40'
        ' 0.30 1.10 0.50 39.15 0.50 104.05 l0 102.25 -1.30 2.65'
        ' c-0.80 1.60 -2.15 3.20 -3.35 4.10 -4 2.90 -4.50 2.95 -33.30 2.90'
        ' -14.45 0 -26.90 -0.20 -27.65 -0.45z',
    dir: _RevealDir.bottomTop,
    t0: 0.84,
    t1: 0.98,
  ),
];

// ─── SVG path parser helper ───────────────────────────────────────────────────

class _FlutterPathProxy extends PathProxy {
  final Path path = Path();

  @override
  void close() => path.close();

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) => path.cubicTo(x1, y1, x2, y2, x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

Path _parseSvgPath(String d) {
  final proxy = _FlutterPathProxy();
  writeSvgPathDataToPath(d, proxy);
  return proxy.path;
}

// ─── Build segments list (called once on first use) ───────────────────────────

List<_Segment> _buildSegments() {
  return [
    for (final def in _segDefs)
      () {
        final p = _parseSvgPath(def.d);
        return _Segment(p, p.getBounds(), def.dir, def.t0, def.t1);
      }(),
  ];
}

// ─── CustomPainter ────────────────────────────────────────────────────────────

class _LogoPainter extends CustomPainter {
  final List<_Segment> segments;
  final double progress; // 0.0–1.0 (already eased at the global level)
  final Color color;

  static const _svgW = 1824.0;
  static const _svgH = 309.0;

  const _LogoPainter({
    required this.segments,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / _svgW, size.height / _svgH);
    final dx = (size.width - _svgW * scale) / 2;
    final dy = (size.height - _svgH * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()..color = color;

    for (final seg in segments) {
      // How far through this segment's window we are (0–1)
      final raw = ((progress - seg.t0) / (seg.t1 - seg.t0)).clamp(0.0, 1.0);
      if (raw == 0.0) continue;

      // Per-segment easing: easeOutCubic gives each stroke a crisp snap
      final t = Curves.easeOutCubic.transform(raw);

      final b = seg.bounds;
      final Rect clip;
      switch (seg.dir) {
        case _RevealDir.bottomTop:
          // Reveal upward: clip grows from bottom edge toward top
          clip = Rect.fromLTRB(
            b.left - 1,
            b.bottom - b.height * t - 1,
            b.right + 1,
            b.bottom + 1,
          );
        case _RevealDir.topBottom:
          clip = Rect.fromLTRB(
            b.left - 1,
            b.top - 1,
            b.right + 1,
            b.top + b.height * t + 1,
          );
        case _RevealDir.leftRight:
          // Reveal rightward: clip grows from left edge toward right
          clip = Rect.fromLTRB(
            b.left - 1,
            b.top - 1,
            b.left + b.width * t + 1,
            b.bottom + 1,
          );
        case _RevealDir.rightLeft:
          clip = Rect.fromLTRB(
            b.right - b.width * t - 1,
            b.top - 1,
            b.right + 1,
            b.bottom + 1,
          );
      }

      canvas.save();
      canvas.clipRect(clip);
      canvas.drawPath(seg.path, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.progress != progress;
}

// ─── Logo animation widget ────────────────────────────────────────────────────

class _LogoAnimation extends StatelessWidget {
  final List<_Segment> segments;
  final Animation<double> animation;
  final Color color;

  const _LogoAnimation({
    required this.segments,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the 1824:309 aspect ratio, fitting within available width.
        const aspect = 1824.0 / 309.0;
        final w = constraints.maxWidth;
        final h = w / aspect;
        return AnimatedBuilder(
          animation: animation,
          builder: (_, _) => RepaintBoundary(
            child: CustomPaint(
              painter: _LogoPainter(
                segments: segments,
                progress: animation.value,
                color: color,
              ),
              size: Size(w, h),
            ),
          ),
        );
      },
    );
  }
}

// ─── Splash screen ────────────────────────────────────────────────────────────

/// Shows an animated KREDIT wordmark while [creditsProvider] loads.
/// Waits for BOTH the logo animation AND the DB load to complete before
/// fading out to reveal [child].
class SplashScreen extends ConsumerStatefulWidget {
  final Widget child;

  const SplashScreen({required this.child, super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Logo reveal: 2 200 ms, linear controller — easing is per-segment
  late final AnimationController _logo;

  // Splash fade-out: misma curva/duración que _TabFadeLayer en main.dart
  late final AnimationController _fade;
  late final CurvedAnimation _fadeAnim;

  late final List<_Segment> _segments;
  late final CurvedAnimation _logoAnim;

  // Phase flags:
  //   _logoDone  → animation finished, child is now in tree and loading data
  //   _dataReady → creditsProvider is no longer loading
  //   _hiding    → fade-out has started (prevent double-trigger)
  bool _logoDone = false;
  bool _dataReady = false;
  bool _hiding = false;

  @override
  void initState() {
    super.initState();

    // Parse SVG paths synchronously — 16 paths, completes in <1 ms.
    _segments = _buildSegments();

    _logo = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _logoAnim = CurvedAnimation(parent: _logo, curve: Curves.easeInOut);

    _fade = AnimationController(
      duration: const Duration(milliseconds: 340),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);

    // Start animation immediately. When it finishes, mount the child (which
    // triggers data loading). A short settle delay lets the completed logo
    // breathe before we watch the provider.
    _logo.forward().whenComplete(_onLogoComplete);
  }

  void _onLogoComplete() {
    if (!mounted) return;
    // Mount child → Drift query starts, providers init.
    setState(() => _logoDone = true);
    // Give the engine one frame to mount child before watching the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Small breathing room so the completed logo is visible at least briefly.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() {}); // trigger a rebuild to evaluate _dataReady
      });
    });
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _logo.dispose();
    _fadeAnim.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _tryHide() {
    if (!mounted || _hiding) return;
    if (_logoDone && _dataReady) {
      _hiding = true;
      _fade.forward().whenComplete(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash fully gone — hand off to child widget directly.
    if (_fade.isCompleted) return widget.child;

    // Only watch creditsProvider once the child is mounted and loading.
    // This prevents the heavy Drift/accrual work from competing with the
    // ticker during the animation phase.
    if (_logoDone && !_dataReady) {
      final credits = ref.watch(creditsProvider);
      if (!credits.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_dataReady && mounted) {
            prewarmCardCaches(credits.value ?? []);
            _dataReady = true;
            _tryHide();
          }
        });
      }
    }

    final prefs = ref.watch(themePreferencesProvider);
    final isDark = prefs.isDarkMode;
    final bgColor = isDark ? AppColors.bgPrimary : const Color(0xFFFFFFFF);
    final fgColor = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);

    return Stack(
      children: [
        // Child only enters the tree after the logo animation finishes.
        // This isolates the heavy widget build + DB query from the ticker,
        // eliminating the freeze during the animation.
        if (_logoDone) widget.child,

        // Splash overlay — fades out once both gates open.
        AnimatedBuilder(
          animation: _fadeAnim,
          child: _SplashContent(
            segments: _segments,
            logoAnim: _logoAnim,
            bgColor: bgColor,
            fgColor: fgColor,
          ),
          builder: (_, child) => IgnorePointer(
            child: Opacity(opacity: 1.0 - _fadeAnim.value, child: child),
          ),
        ),
      ],
    );
  }
}

// ─── Visual content of the splash ────────────────────────────────────────────

class _SplashContent extends StatelessWidget {
  final List<_Segment> segments;
  final Animation<double> logoAnim;
  final Color bgColor;
  final Color fgColor;

  const _SplashContent({
    required this.segments,
    required this.logoAnim,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LogoAnimation(
                segments: segments,
                animation: logoAnim,
                color: fgColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
