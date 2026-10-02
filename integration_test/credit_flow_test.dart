import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kredit/main.dart' as app;

// app.main() / runApp() must be called exactly once per process.
bool _appLaunched = false;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launchAppOnce(WidgetTester tester) async {
    if (!_appLaunched) {
      _appLaunched = true;
      app.main();
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
    } else {
      // Already running: just sync one frame to stabilize.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> openAddCreditSheet(WidgetTester tester) async {
    // Dashboard FAB hides when credit list is empty (fresh install).
    // Navigate to the "Créditos" tab whose FAB always shows.
    final creditsTab = find.text('Créditos');
    if (creditsTab.evaluate().isNotEmpty) {
      await tester.tap(creditsTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.byTooltip('Agregar Crédito'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> closeSheet(WidgetTester tester) async {
    // Pop the /add-credit route to return to the credits tab.
    final nav = find.byType(Navigator);
    if (nav.evaluate().isNotEmpty) {
      tester.state<NavigatorState>(nav).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  group('Credit creation flow — mode selector redesign', () {
    testWidgets('A — mode selector shows 3 options', (tester) async {
      await launchAppOnce(tester);
      await openAddCreditSheet(tester);

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Cupo de tienda'), findsOneWidget);
      expect(find.text('Tarjeta bancaria'), findsOneWidget);
      expect(find.text('Préstamo bancario'), findsOneWidget);

      await closeSheet(tester);
    });

    testWidgets(
        'B — tienda flow: tap card navigates to step 0, back returns to selector',
        (tester) async {
      await launchAppOnce(tester);
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

      await closeSheet(tester);
    });

    testWidgets('C — tarjeta flow: navigates all 5 steps and reaches confirm',
        (tester) async {
      await launchAppOnce(tester);
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

      await closeSheet(tester);
    });

    testWidgets('D — prestamo flow: tap card navigates to step 0',
        (tester) async {
      await launchAppOnce(tester);
      await openAddCreditSheet(tester);

      await tester.tap(find.text('Préstamo bancario'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Banco'), findsWidgets);
    });
  });
}
