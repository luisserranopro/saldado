// Lógica de las cuentas: no depende de Flutter ni de la base de datos,
// así se puede probar con tests unitarios (test/cuentas_test.dart).

import '../i18n.dart';
import '../models/modelos.dart';

/// Reparte [total] céntimos entre [personas] a partes iguales.
/// Si no es divisible, los céntimos que sobran se dan de uno en uno a los
/// primeros: 10,00 € entre 3 = 3,34 + 3,33 + 3,33. La suma siempre es exacta.
List<int> repartirIgual(int total, int personas) {
  if (personas <= 0) return const [];
  final base = total ~/ personas;
  final resto = total % personas;
  return List.generate(personas, (i) => base + (i < resto ? 1 : 0));
}

/// Saldo de cada miembro (céntimos). Positivo: le deben dinero.
/// Negativo: debe dinero. La suma de todos los saldos siempre es 0.
///
/// - Quien paga un gasto suma el importe; cada participante resta su parte.
/// - Un pago de A a B: A suma (ha devuelto) y B resta (ha cobrado).
Map<int, int> calcularSaldos(List<Miembro> miembros, List<Gasto> gastos, List<Pago> pagos) {
  final saldos = {for (final m in miembros) m.id!: 0};
  void sumar(int id, int cantidad) => saldos[id] = (saldos[id] ?? 0) + cantidad;

  for (final g in gastos) {
    sumar(g.pagadorId, g.importe);
    for (final p in g.partes) {
      sumar(p.miembroId, -p.importe);
    }
  }
  for (final p in pagos) {
    sumar(p.deId, p.importe);
    sumar(p.aId, -p.importe);
  }
  return saldos;
}

/// Lo que cada miembro ha pagado en total y lo que le correspondía (sus partes).
class Totales {
  final int pagado;
  final int consumido;

  const Totales(this.pagado, this.consumido);
}

Map<int, Totales> calcularTotales(List<Miembro> miembros, List<Gasto> gastos) {
  final pagado = {for (final m in miembros) m.id!: 0};
  final consumido = {for (final m in miembros) m.id!: 0};
  for (final g in gastos) {
    pagado[g.pagadorId] = (pagado[g.pagadorId] ?? 0) + g.importe;
    for (final p in g.partes) {
      consumido[p.miembroId] = (consumido[p.miembroId] ?? 0) + p.importe;
    }
  }
  return {for (final id in pagado.keys) id: Totales(pagado[id]!, consumido[id] ?? 0)};
}

/// Una transferencia para saldar las cuentas: [deId] le paga [importe] a [aId].
class Transferencia {
  final int deId;
  final int aId;
  final int importe;

  const Transferencia(this.deId, this.aId, this.importe);

  @override
  bool operator ==(Object other) =>
      other is Transferencia && other.deId == deId && other.aId == aId && other.importe == importe;

  @override
  int get hashCode => Object.hash(deId, aId, importe);

  @override
  String toString() => 'Transferencia($deId -> $aId: $importe)';
}

/// Calcula pocas transferencias que dejan todos los saldos a cero.
///
/// Algoritmo voraz: en cada paso, quien más debe le paga a quien más le deben
/// la menor de las dos cantidades. Como en cada paso al menos uno de los dos
/// queda a cero, con n personas salen como mucho n - 1 transferencias.
List<Transferencia> liquidar(Map<int, int> saldos) {
  // Copias de trabajo: [id, cantidad pendiente]
  final deudores = [
    for (final e in saldos.entries)
      if (e.value < 0) [e.key, -e.value]
  ];
  final acreedores = [
    for (final e in saldos.entries)
      if (e.value > 0) [e.key, e.value]
  ];

  final resultado = <Transferencia>[];
  while (deudores.isNotEmpty && acreedores.isNotEmpty) {
    // Ordenar de mayor a menor; a igualdad, por id (resultado siempre igual)
    int orden(List<int> a, List<int> b) =>
        b[1] != a[1] ? b[1].compareTo(a[1]) : a[0].compareTo(b[0]);
    deudores.sort(orden);
    acreedores.sort(orden);

    final deudor = deudores.first;
    final acreedor = acreedores.first;
    final cantidad = deudor[1] < acreedor[1] ? deudor[1] : acreedor[1];

    resultado.add(Transferencia(deudor[0], acreedor[0], cantidad));
    deudor[1] -= cantidad;
    acreedor[1] -= cantidad;
    if (deudor[1] == 0) deudores.removeAt(0);
    if (acreedor[1] == 0) acreedores.removeAt(0);
  }
  return resultado;
}

/// 123456 céntimos -> "1.234,56 €" en español (o "$1.234,56" según la moneda)
/// y "€1,234.56" en inglés.
String formatearImporte(int centimos, Moneda moneda, {bool conSigno = false}) {
  final es = Idioma.es;
  final sepMiles = es ? '.' : ',';
  final sepDecimal = es ? ',' : '.';
  final negativo = centimos < 0;
  final abs = centimos.abs();
  final enteros = (abs ~/ 100).toString();
  final decimales = (abs % 100).toString().padLeft(2, '0');

  // Separador de miles con punto: 1234567 -> 1.234.567
  final grupos = <String>[];
  for (var i = enteros.length; i > 0; i -= 3) {
    grupos.insert(0, enteros.substring(i - 3 < 0 ? 0 : i - 3, i));
  }
  final numero = '${grupos.join(sepMiles)}$sepDecimal$decimales';

  final signo = negativo ? '−' : (conSigno && centimos > 0 ? '+' : '');
  // En inglés el símbolo va delante (€12.50); el franco suizo, con espacio.
  if (moneda.simboloDelante || !es) {
    final espacio = moneda.simbolo.length > 1 ? ' ' : '';
    return '$signo${moneda.simbolo}$espacio$numero';
  }
  return '$signo$numero ${moneda.simbolo}';
}

/// Convierte lo que escribe el usuario en céntimos, o null si no es válido.
/// Acepta "12", "12,5", "12.50", "1.234,56", "1,234.56" y "1234.5".
/// El último punto o coma seguido de 1 o 2 cifras se toma como decimal;
/// el resto de puntos y comas, como separadores de miles.
int? parsearImporte(String texto) {
  var t = texto.trim().replaceAll(' ', '').replaceAll('€', '').replaceAll(r'$', '');
  if (t.isEmpty) return null;
  if (!RegExp(r'^[0-9.,]+$').hasMatch(t)) return null;

  final decimal = RegExp(r'[.,](\d{1,2})$').firstMatch(t);
  String parteEntera;
  String parteDecimal = '';
  if (decimal != null) {
    parteEntera = t.substring(0, decimal.start);
    parteDecimal = decimal.group(1)!;
  } else {
    parteEntera = t;
  }
  parteEntera = parteEntera.replaceAll('.', '').replaceAll(',', '');
  if (parteEntera.isEmpty) parteEntera = '0';
  if (!RegExp(r'^\d+$').hasMatch(parteEntera)) return null;
  // Límite razonable (hasta 999.999.999): evita desbordar int al multiplicar
  if (parteEntera.length > 9) return null;

  final euros = int.parse(parteEntera);
  final centimos = int.parse(parteDecimal.padRight(2, '0'));
  return euros * 100 + centimos;
}
