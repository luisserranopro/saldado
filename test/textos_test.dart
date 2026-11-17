import 'package:flutter_test/flutter_test.dart';
import 'package:saldado/i18n.dart';
import 'package:saldado/logica/cuentas.dart';
import 'package:saldado/logica/textos.dart';
import 'package:saldado/models/modelos.dart';

void main() {
  // Los textos esperados de estos tests están en español
  setUp(() => Idioma.forzar('es'));
  tearDown(() => Idioma.forzar(null));

  test('cabeceraDia', () {
    final ahora = DateTime(2026, 11, 16, 12); // lunes
    expect(cabeceraDia(DateTime(2026, 11, 16, 9), ahora: ahora), 'Hoy');
    expect(cabeceraDia(DateTime(2026, 11, 15, 23), ahora: ahora), 'Ayer');
    expect(cabeceraDia(DateTime(2026, 11, 9), ahora: ahora), 'lunes, 9 nov');
    expect(cabeceraDia(DateTime(2025, 12, 31), ahora: ahora), 'miércoles, 31 dic 2025');
  });

  test('fechaCorta', () {
    expect(fechaCorta(DateTime(2026, 9, 3)), '3 sept 2026');
  });

  test('textoResumen incluye saldos y cómo saldar', () {
    final miembros = [
      const Miembro(id: 1, grupoId: 1, nombre: 'Ana'),
      const Miembro(id: 2, grupoId: 1, nombre: 'Luis'),
    ];
    final cuotas = repartirIgual(3000, 2);
    final datos = DatosGrupo(
      grupo: Grupo(id: 1, nombre: 'Viaje', moneda: 'EUR', creado: DateTime(2026)),
      miembros: miembros,
      gastos: [
        Gasto(
          grupoId: 1,
          concepto: 'Hotel',
          importe: 3000,
          pagadorId: 1,
          fecha: DateTime(2026),
          categoria: Categoria.alojamiento,
          partes: [Parte(1, cuotas[0]), Parte(2, cuotas[1])],
        ),
      ],
      pagos: const [],
    );
    final texto = textoResumen(datos);
    expect(texto, contains('Total gastado: 30,00 €'));
    expect(texto, contains('• Ana: +15,00 €'));
    expect(texto, contains('• Luis: −15,00 €'));
    expect(texto, contains('• Luis → Ana: 15,00 €'));
  });

  group('en inglés', () {
    setUp(() => Idioma.forzar('en'));

    test('fechas', () {
      final ahora = DateTime(2026, 11, 16, 12);
      expect(cabeceraDia(DateTime(2026, 11, 16, 9), ahora: ahora), 'Today');
      expect(cabeceraDia(DateTime(2026, 11, 15), ahora: ahora), 'Yesterday');
      expect(cabeceraDia(DateTime(2026, 11, 9), ahora: ahora), 'Monday, 9 Nov');
      expect(fechaCorta(DateTime(2026, 9, 3)), '3 Sep 2026');
    });

    test('importes con formato inglés', () {
      const euro = Moneda('EUR', '€', 'Euro');
      const franco = Moneda('CHF', 'CHF', 'Franco suizo', nombreEn: 'Swiss franc');
      expect(formatearImporte(123456, euro), '€1,234.56');
      expect(formatearImporte(-1250, euro), '−€12.50');
      expect(formatearImporte(1250, franco), 'CHF 12.50');
      expect(parsearImporte('1,234.56'), 123456);
    });

    test('categorías y monedas traducidas', () {
      expect(Categoria.comida.nombre, 'Food & drink');
      expect(Moneda.porCodigo('GBP').nombre, 'Pound sterling');
    });
  });
}
