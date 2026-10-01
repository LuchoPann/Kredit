import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kredit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Credit creation flow — mode selector redesign', () {
    setUp(() async {
      app.main();
      await Future.delayed(const Duration(seconds: 3));
    });

    // ─── Helpers ────────────────────────────────────────────────────────────

    Future<void> openAddCreditSheet(WidgetTester tester) async {
      // Intenta el FAB del dashboard primero; si no, busca el de créditos
      final fab = find.byTooltip('Agregar crédito');
      if (fab.evaluate().isEmpty) {
        // El FAB puede no tener tooltip — busca por Icon
        final iconBtn = find.widgetWithIcon(FloatingActionButton, Icons.add);
        if (iconBtn.evaluate().isNotEmpty) {
          await tester.tap(iconBtn.first);
        } else {
          // Navega a la pantalla de créditos y usa su botón
          await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).first);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add).first);
        }
      } else {
        await tester.tap(fab.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    Future<void> waitForText(WidgetTester tester, String text,
        {int maxRetries = 10}) async {
      for (var i = 0; i < maxRetries; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.text(text).evaluate().isNotEmpty) return;
      }
    }

    // ─── Test A: selector de modo muestra las 3 opciones ────────────────────

    testWidgets('A — mode selector shows 3 options', (tester) async {
      await tester.pumpWidget(const SizedBox()); // reset
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await openAddCreditSheet(tester);

      await waitForText(tester, '¿Qué quieres registrar?');

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
      expect(find.text('Cupo de tienda'), findsOneWidget);
      expect(find.text('Tarjeta bancaria'), findsOneWidget);
      expect(find.text('Préstamo bancario'), findsOneWidget);
    });

    // ─── Test B: Flow tienda — selector → paso 0 → back al selector ─────────

    testWidgets('B — tienda flow: tap card navigates to step 0, back returns to selector',
        (tester) async {
      await tester.pumpWidget(const SizedBox());
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await openAddCreditSheet(tester);
      await waitForText(tester, 'Cupo de tienda');

      // Tap en la tarjeta de tienda
      await tester.tap(find.text('Cupo de tienda'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Debe mostrar paso 0 — selección de entidad
      expect(find.text('Entidad'), findsWidgets);

      // Back al selector
      final backBtn = find.text('← Cambiar tipo');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('¿Qué quieres registrar?'), findsOneWidget);
    });

    // ─── Test C: Flow tarjeta — completo hasta confirmar ────────────────────

    testWidgets('C — tarjeta flow: navigates all 5 steps and reaches confirm',
        (tester) async {
      await tester.pumpWidget(const SizedBox());
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await openAddCreditSheet(tester);
      await waitForText(tester, 'Tarjeta bancaria');

      await tester.tap(find.text('Tarjeta bancaria'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 0 — Banco: pick primer chip disponible
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pumpAndSettle();
      }
      // Siguiente
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 1 — Cupo y deuda: llenar cupo
      final cupoField = find.widgetWithText(TextFormField, '');
      if (cupoField.evaluate().isNotEmpty) {
        await tester.enterText(cupoField.first, '5000000');
        await tester.pump();
      }
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 2 — Condiciones: solo siguiente
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 3 — Ciclo: solo siguiente
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 4 — Confirmar
      expect(find.text('Confirmar'), findsWidgets);
    });

    // ─── Test D: Flow préstamo — selector → paso 0 ──────────────────────────

    testWidgets('D — prestamo flow: tap card navigates to step 0', (tester) async {
      await tester.pumpWidget(const SizedBox());
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await openAddCreditSheet(tester);
      await waitForText(tester, 'Préstamo bancario');

      await tester.tap(find.text('Préstamo bancario'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Paso 0 — Banco
      expect(find.text('Banco'), findsWidgets);
    });
  });
}
