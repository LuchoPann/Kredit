import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kredit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Correct integration-test pattern on real devices:
  // call app.main() (→ runApp), then tester.pump() to process frames.
  // Never use tester.pumpWidget() — it conflicts with the live Activity/View
  // and leaves _pendingFrame unresolved because vsyncs go to the real view.

  Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> openAddCreditSheet(WidgetTester tester) async {
    // Correct tooltip (capital C): 'Agregar Crédito'
    final fab = find.byTooltip('Agregar Crédito');
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
    } else {
      // Dashboard still loading — credits tab FAB
      final tabFab = find.widgetWithIcon(FloatingActionButton, Icons.add);
      await tester.tap(tabFab.first);
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('Credit creation flow — mode selector redesign', () {
    // ─── A: selector muestra las 3 opciones ─────────────────────────────────

    testWidgets('A — mode selector shows 3 options', (tester) async {
      await launchApp(tester);
      await openAddCreditSheet(tester);

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Cupo de tienda'), findsOneWidget);
      expect(find.text('Tarjeta bancaria'), findsOneWidget);
      expect(find.text('Préstamo bancario'), findsOneWidget);
    });

    // ─── B: tienda → paso 0, back al selector ───────────────────────────────

    testWidgets(
        'B — tienda flow: tap card navigates to step 0, back returns to selector',
        (tester) async {
      await launchApp(tester);
      await openAddCreditSheet(tester);

      await tester.tap(find.text('Cupo de tienda'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Entidad'), findsWidgets);

      final backBtn = find.text('← Cambiar tipo');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
    });

    // ─── C: tarjeta → 5 pasos hasta confirmar ───────────────────────────────

    testWidgets('C — tarjeta flow: navigates all 5 steps and reaches confirm',
        (tester) async {
      await launchApp(tester);
      await openAddCreditSheet(tester);

      await tester.tap(find.text('Tarjeta bancaria'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Paso 0 — Banco
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pump();
      }
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Paso 1 — Cupo y deuda
      final cupoFields = find.byType(TextFormField);
      if (cupoFields.evaluate().isNotEmpty) {
        await tester.enterText(cupoFields.first, '5000000');
        await tester.pump();
      }
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Paso 2 — Condiciones
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Paso 3 — Ciclo
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Paso 4 — Confirmar
      expect(find.text('Confirmar'), findsWidgets);
    });

    // ─── D: préstamo → paso 0 banco ─────────────────────────────────────────

    testWidgets('D — prestamo flow: tap card navigates to step 0',
        (tester) async {
      await launchApp(tester);
      await openAddCreditSheet(tester);

      await tester.tap(find.text('Préstamo bancario'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Banco'), findsWidgets);
    });
  });
}
