import 'package:flutter/material.dart';

import '../i18n.dart';

// IMPORTANTE: todos los importes se guardan como números ENTEROS de céntimos
// (12,50 € = 1250). Con double, 0.1 + 0.2 da 0.30000000000000004 y al repartir
// gastos se acaban perdiendo o inventando céntimos.

/// Monedas disponibles para un grupo.
class Moneda {
  final String codigo;
  final String simbolo;
  final bool simboloDelante;
  final String nombreEs;
  final String nombreEn;

  const Moneda(this.codigo, this.simbolo, this.nombreEs,
      {this.simboloDelante = false, String? nombreEn})
      : nombreEn = nombreEn ?? nombreEs;

  String get nombre => Idioma.es ? nombreEs : nombreEn;

  static const lista = [
    Moneda('EUR', '€', 'Euro'),
    Moneda('USD', r'$', 'Dólar estadounidense',
        simboloDelante: true, nombreEn: 'US dollar'),
    Moneda('GBP', '£', 'Libra esterlina', simboloDelante: true, nombreEn: 'Pound sterling'),
    Moneda('MXN', r'$', 'Peso mexicano', simboloDelante: true, nombreEn: 'Mexican peso'),
    Moneda('CHF', 'CHF', 'Franco suizo', nombreEn: 'Swiss franc'),
  ];

  static Moneda porCodigo(String codigo) =>
      lista.firstWhere((m) => m.codigo == codigo, orElse: () => lista.first);
}

class Grupo {
  final int? id;
  final String nombre;
  final String moneda; // código: "EUR"...
  final DateTime creado;

  const Grupo({this.id, required this.nombre, required this.moneda, required this.creado});

  Moneda get datosMoneda => Moneda.porCodigo(moneda);

  Map<String, Object?> aMapa() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'moneda': moneda,
        'creado': creado.millisecondsSinceEpoch,
      };

  factory Grupo.desdeMapa(Map<String, Object?> m) => Grupo(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        moneda: m['moneda'] as String,
        creado: DateTime.fromMillisecondsSinceEpoch(m['creado'] as int),
      );
}

class Miembro {
  final int? id;
  final int grupoId;
  final String nombre;

  const Miembro({this.id, required this.grupoId, required this.nombre});

  factory Miembro.desdeMapa(Map<String, Object?> m) => Miembro(
        id: m['id'] as int,
        grupoId: m['grupo_id'] as int,
        nombre: m['nombre'] as String,
      );
}

enum Categoria {
  comida('Comida y bebida', 'Food & drink', Icons.restaurant_rounded, Color(0xFFE8833A)),
  compra('Supermercado', 'Groceries', Icons.shopping_cart_rounded, Color(0xFF3F8EFC)),
  transporte('Transporte', 'Transport', Icons.directions_car_rounded, Color(0xFF7B61FF)),
  alojamiento('Alojamiento', 'Accommodation', Icons.hotel_rounded, Color(0xFF0E9F7E)),
  ocio('Ocio', 'Entertainment', Icons.local_activity_rounded, Color(0xFFE5487A)),
  hogar('Casa y facturas', 'Home & bills', Icons.home_rounded, Color(0xFF8C6D4F)),
  otros('Otros', 'Other', Icons.receipt_long_rounded, Color(0xFF6B7C78));

  final String nombreEs;
  final String nombreEn;
  final IconData icono;
  final Color color;

  const Categoria(this.nombreEs, this.nombreEn, this.icono, this.color);

  String get nombre => Idioma.es ? nombreEs : nombreEn;

  static Categoria porNombre(String n) =>
      Categoria.values.firstWhere((c) => c.name == n, orElse: () => Categoria.otros);
}

/// Lo que le corresponde pagar a un miembro de un gasto.
class Parte {
  final int miembroId;
  final int importe; // céntimos

  const Parte(this.miembroId, this.importe);
}

class Gasto {
  final int? id;
  final int grupoId;
  final String concepto;
  final int importe; // céntimos
  final int pagadorId;
  final DateTime fecha;
  final Categoria categoria;
  final List<Parte> partes; // la suma de las partes es igual a importe

  const Gasto({
    this.id,
    required this.grupoId,
    required this.concepto,
    required this.importe,
    required this.pagadorId,
    required this.fecha,
    required this.categoria,
    required this.partes,
  });

  Map<String, Object?> aMapa() => {
        if (id != null) 'id': id,
        'grupo_id': grupoId,
        'concepto': concepto,
        'importe': importe,
        'pagador_id': pagadorId,
        'fecha': fecha.millisecondsSinceEpoch,
        'categoria': categoria.name,
      };
}

/// Dinero que un miembro le da a otro para saldar deudas (no es un gasto).
class Pago {
  final int? id;
  final int grupoId;
  final int deId;
  final int aId;
  final int importe; // céntimos
  final DateTime fecha;

  const Pago({
    this.id,
    required this.grupoId,
    required this.deId,
    required this.aId,
    required this.importe,
    required this.fecha,
  });

  Map<String, Object?> aMapa() => {
        if (id != null) 'id': id,
        'grupo_id': grupoId,
        'de_id': deId,
        'a_id': aId,
        'importe': importe,
        'fecha': fecha.millisecondsSinceEpoch,
      };

  factory Pago.desdeMapa(Map<String, Object?> m) => Pago(
        id: m['id'] as int,
        grupoId: m['grupo_id'] as int,
        deId: m['de_id'] as int,
        aId: m['a_id'] as int,
        importe: m['importe'] as int,
        fecha: DateTime.fromMillisecondsSinceEpoch(m['fecha'] as int),
      );
}

/// Todo lo que hace falta para mostrar un grupo.
class DatosGrupo {
  final Grupo grupo;
  final List<Miembro> miembros;
  final List<Gasto> gastos;
  final List<Pago> pagos;

  const DatosGrupo({
    required this.grupo,
    required this.miembros,
    required this.gastos,
    required this.pagos,
  });

  String nombreDe(int miembroId) =>
      miembros.where((m) => m.id == miembroId).map((m) => m.nombre).firstOrNull ?? '?';

  int get totalGastado => gastos.fold(0, (suma, g) => suma + g.importe);
}

/// Resumen de un grupo para la lista de la pantalla principal.
class ResumenGrupo {
  final Grupo grupo;
  final int numMiembros;
  final int total; // céntimos

  const ResumenGrupo(this.grupo, this.numMiembros, this.total);
}
