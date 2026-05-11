// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/app.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';

// Mock simple para evitar dependencias de Supabase en el test de widgets
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override bool get isLoggedIn => false;
  @override bool get isLoading => false;
  @override String? get error => null;
  @override dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Smoke test: Verifica que la app carga sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConfigProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider() as AuthProvider),
        ],
        child: const GestionAusencias(),
      ),
    );

    // Verifica que la clase principal se ha instanciado correctamente
    expect(find.byType(GestionAusencias), findsOneWidget);
  });
}
