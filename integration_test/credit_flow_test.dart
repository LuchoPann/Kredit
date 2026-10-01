import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kredit/data/db/database.dart';
import 'package:kredit/providers/database_provider.dart';
import 'package:kredit/screens/credits/add_credit_sheet.dart';
import 'package:kredit/theme/app_theme.dart';

// Pump helper: steps through frames without waiting for animations to settle.
Future<void> pumpFrames(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(AppDatabase db) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: buildAppTheme(isDarkMode: false),
        home: const Scaffold(body: AddCreditSheet()),
      ),
    );
  }

  group('Credit creation flow — mode selector redesign', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ─── A: selector de modo muestra las 3 opciones ─────────────────────────

    testWidgets('A — mode selector shows 3 options',
        timeout: const Timeout(Duration(minutes: 3)), (tester) async {
      await tester.pumpWidget(buildTestApp(db));
      await pumpFrames(tester, frames: 60);

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Cupo de tienda'), findsOneWidget);
      expect(find.text('Tarjeta bancaria'), findsOneWidget);
      expect(find.text('Préstamo bancario'), findsOneWidget);
    });

    // ─── B: tienda → paso 0, back al selector ───────────────────────────────

    testWidgets(
        'B — tienda flow: tap card navigates to step 0, back returns to selector',
        timeout: const Timeout(Duration(minutes: 3)), (tester) async {
      await tester.pumpWidget(buildTestApp(db));
      await pumpFrames(tester, frames: 60);

      await tester.tap(find.text('Cupo de tienda'));
      await pumpFrames(tester, frames: 30);

      expect(find.text('Entidad'), findsWidgets);

      final backBtn = find.text('← Cambiar tipo');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await pumpFrames(tester, frames: 30);

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
    });

    // ─── C: tarjeta → 5 pasos hasta confirmar ───────────────────────────────

    testWidgets('C — tarjeta flow: navigates all 5 steps and reaches confirm',
        timeout: const Timeout(Duration(minutes: 3)), (tester) async {
      await tester.pumpWidget(buildTestApp(db));
      await pumpFrames(tester, frames: 60);

      await tester.tap(find.text('Tarjeta bancaria'));
      await pumpFrames(tester, frames: 30);

      // Paso 0 — Banco: pick primer FilterChip si hay
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await pumpFrames(tester, frames: 10);
      }
      await tester.tap(find.text('Siguiente'));
      await pumpFrames(tester, frames: 30);

      // Paso 1 — Cupo y deuda
      final cupoFields = find.byType(TextFormField);
      if (cupoFields.evaluate().isNotEmpty) {
        await tester.enterText(cupoFields.first, '5000000');
        await pumpFrames(tester, frames: 10);
      }
      await tester.tap(find.text('Siguiente'));
      await pumpFrames(tester, frames: 30);

      // Paso 2 — Condiciones
      await tester.tap(find.text('Siguiente'));
      await pumpFrames(tester, frames: 30);

      // Paso 3 — Ciclo
      await tester.tap(find.text('Siguiente'));
      await pumpFrames(tester, frames: 30);

      // Paso 4 — Confirmar
      expect(find.text('Confirmar'), findsWidgets);
    });

    // ─── D: préstamo → paso 0 banco ─────────────────────────────────────────

    testWidgets('D — prestamo flow: tap card navigates to step 0',
        timeout: const Timeout(Duration(minutes: 3)), (tester) async {
      await tester.pumpWidget(buildTestApp(db));
      await pumpFrames(tester, frames: 60);

      await tester.tap(find.text('Préstamo bancario'));
      await pumpFrames(tester, frames: 30);

      expect(find.text('Banco'), findsWidgets);
    });
  });
}
