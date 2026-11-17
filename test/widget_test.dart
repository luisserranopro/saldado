// Prueba de widgets sencilla. (Este archivo evita que `flutter create`
// genere el test de ejemplo del contador, que no compila con esta app.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldado/i18n.dart';
import 'package:saldado/models/modelos.dart';
import 'package:saldado/tema.dart';
import 'package:saldado/widgets/comunes.dart';

void main() {
  // Los textos esperados de estos tests están en español
  setUp(() => Idioma.forzar('es'));
  tearDown(() => Idioma.forzar(null));

  testWidgets('AvatarMiembro muestra la inicial en mayúscula', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: temaSaldado(),
      home: const Scaffold(body: AvatarMiembro(nombre: 'ana', indice: 0)),
    ));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('TextoSaldo indica si le deben o debe', (tester) async {
    const euro = Moneda('EUR', '€', 'Euro');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          TextoSaldo(saldo: 1500, moneda: euro),
          TextoSaldo(saldo: -800, moneda: euro),
        ]),
      ),
    ));
    expect(find.text('+15,00 €'), findsOneWidget);
    expect(find.text('le deben'), findsOneWidget);
    expect(find.text('−8,00 €'), findsOneWidget);
    expect(find.text('debe'), findsOneWidget);
  });
}
