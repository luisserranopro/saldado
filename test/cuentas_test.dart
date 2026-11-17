import 'package:flutter_test/flutter_test.dart';
import 'package:saldado/i18n.dart';
import 'package:saldado/logica/cuentas.dart';
import 'package:saldado/models/modelos.dart';

void main() {
  // Los textos esperados de estos tests están en español
  setUp(() => Idioma.forzar('es'));
  tearDown(() => Idioma.forzar(null));

  group('repartirIgual', () {
    test('reparte exacto cuando es divisible', () {
      expect(repartirIgual(900, 3), [300, 300, 300]);
    });
    test('los céntimos sobrantes van a los primeros y la suma cuadra', () {
      final partes = repartirIgual(1000, 3);
      expect(partes, [334, 333, 333]);
      expect(partes.reduce((a, b) => a + b), 1000);
    });
    test('sin personas devuelve lista vacía', () {
      expect(repartirIgual(1000, 0), isEmpty);
    });
  });

  // Ana (1), Luis (2) y Eva (3)
  final miembros = [
    const Miembro(id: 1, grupoId: 1, nombre: 'Ana'),
    const Miembro(id: 2, grupoId: 1, nombre: 'Luis'),
    const Miembro(id: 3, grupoId: 1, nombre: 'Eva'),
  ];
  Gasto gasto(int pagador, int importe, List<int> participantes) {
    final cuotas = repartirIgual(importe, participantes.length);
    return Gasto(
      grupoId: 1,
      concepto: 'x',
      importe: importe,
      pagadorId: pagador,
      fecha: DateTime(2026),
      categoria: Categoria.otros,
      partes: [for (var i = 0; i < participantes.length; i++) Parte(participantes[i], cuotas[i])],
    );
  }

  group('calcularSaldos', () {
    test('quien paga para todos queda a favor y los demás en contra', () {
      final saldos = calcularSaldos(miembros, [gasto(1, 3000, [1, 2, 3])], []);
      expect(saldos, {1: 2000, 2: -1000, 3: -1000});
    });
    test('la suma de los saldos siempre es cero', () {
      final saldos = calcularSaldos(
        miembros,
        [gasto(1, 1000, [1, 2, 3]), gasto(2, 2550, [2, 3]), gasto(3, 799, [1, 3])],
        [],
      );
      expect(saldos.values.reduce((a, b) => a + b), 0);
    });
    test('un pago reduce la deuda', () {
      final saldos = calcularSaldos(
        miembros,
        [gasto(1, 3000, [1, 2, 3])],
        [Pago(grupoId: 1, deId: 2, aId: 1, importe: 1000, fecha: DateTime(2026))],
      );
      expect(saldos, {1: 1000, 2: 0, 3: -1000});
    });
  });

  group('liquidar', () {
    test('todo a cero no necesita transferencias', () {
      expect(liquidar({1: 0, 2: 0}), isEmpty);
    });
    test('dos deudores pagan al acreedor', () {
      expect(liquidar({1: 2000, 2: -1000, 3: -1000}), [
        const Transferencia(2, 1, 1000),
        const Transferencia(3, 1, 1000),
      ]);
    });
    test('deja todos los saldos a cero con n-1 transferencias como mucho', () {
      final saldos = {1: 4500, 2: -3000, 3: 1500, 4: -2000, 5: -1000};
      final transferencias = liquidar(saldos);
      expect(transferencias.length, lessThanOrEqualTo(saldos.length - 1));
      final resultado = Map.of(saldos);
      for (final t in transferencias) {
        resultado[t.deId] = resultado[t.deId]! + t.importe;
        resultado[t.aId] = resultado[t.aId]! - t.importe;
      }
      expect(resultado.values.every((v) => v == 0), isTrue);
    });
  });

  group('formatearImporte', () {
    const euro = Moneda('EUR', '€', 'Euro');
    const dolar = Moneda('USD', r'$', 'Dólar', simboloDelante: true);
    test('euros con miles y decimales', () {
      expect(formatearImporte(123456, euro), '1.234,56 €');
      expect(formatearImporte(5, euro), '0,05 €');
    });
    test('símbolo delante y signos', () {
      expect(formatearImporte(1250, dolar), r'$12,50');
      expect(formatearImporte(-1250, euro), '−12,50 €');
      expect(formatearImporte(1250, euro, conSigno: true), '+12,50 €');
    });
  });

  group('parsearImporte', () {
    test('formatos habituales', () {
      expect(parsearImporte('12'), 1200);
      expect(parsearImporte('12,5'), 1250);
      expect(parsearImporte('12.50'), 1250);
      expect(parsearImporte('1.234,56'), 123456);
      expect(parsearImporte('1,234.56'), 123456);
      expect(parsearImporte(' 7,99 € '), 799);
    });
    test('textos no válidos', () {
      expect(parsearImporte(''), isNull);
      expect(parsearImporte('abc'), isNull);
      expect(parsearImporte('-5'), isNull);
    });
  });
}
