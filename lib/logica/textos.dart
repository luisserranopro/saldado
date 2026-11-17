// Formatos de fecha y el texto del resumen que se comparte por WhatsApp.
// Sin dependencias de Flutter: se prueba en test/textos_test.dart.

import '../i18n.dart';
import '../models/modelos.dart';
import 'cuentas.dart';

const _mesesEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
const _mesesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _diasEs = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _diasEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// "16 nov 2026" / "16 Nov 2026"
String fechaCorta(DateTime d) {
  final meses = Idioma.es ? _mesesEs : _mesesEn;
  return '${d.day} ${meses[d.month - 1]} ${d.year}';
}

/// Cabecera de un día en la lista de gastos: "Hoy", "Ayer" o "lunes, 9 nov"
/// ("Today", "Yesterday" o "Monday, 9 Nov").
String cabeceraDia(DateTime d, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  // En UTC para que un cambio de hora (días de 23 o 25 h) no altere la cuenta
  final diferencia = DateTime.utc(hoy.year, hoy.month, hoy.day)
      .difference(DateTime.utc(d.year, d.month, d.day))
      .inDays;
  if (diferencia == 0) return Tx.hoy;
  if (diferencia == 1) return Tx.ayer;
  final dias = Idioma.es ? _diasEs : _diasEn;
  final meses = Idioma.es ? _mesesEs : _mesesEn;
  final base = '${dias[d.weekday - 1]}, ${d.day} ${meses[d.month - 1]}';
  return d.year == hoy.year ? base : '$base ${d.year}';
}

/// Texto para compartir el estado del grupo.
String textoResumen(DatosGrupo datos) {
  final moneda = datos.grupo.datosMoneda;
  String importe(int c, {bool signo = false}) => formatearImporte(c, moneda, conSigno: signo);

  final saldos = calcularSaldos(datos.miembros, datos.gastos, datos.pagos);
  final transferencias = liquidar(saldos);

  final b = StringBuffer()
    ..writeln('💸 ${datos.grupo.nombre}')
    ..writeln('${Tx.resumenTotal}: ${importe(datos.totalGastado)}')
    ..writeln()
    ..writeln('${Tx.resumenSaldos}:');
  for (final m in datos.miembros) {
    b.writeln('• ${m.nombre}: ${importe(saldos[m.id] ?? 0, signo: true)}');
  }
  b.writeln();
  if (transferencias.isEmpty) {
    b.writeln('✅ ${Tx.resumenTodoSaldado}');
  } else {
    b.writeln('${Tx.resumenParaSaldar}:');
    for (final t in transferencias) {
      b.writeln('• ${datos.nombreDe(t.deId)} → ${datos.nombreDe(t.aId)}: ${importe(t.importe)}');
    }
  }
  b.write('\n${Tx.resumenFirma}');
  return b.toString();
}
