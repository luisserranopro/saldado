import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/modelos.dart';

/// Acceso a la base de datos local (SQLite). Toda la app pasa por aquí.
///
/// Tablas:
///   grupos   (id, nombre, moneda, creado)
///   miembros (id, grupo_id, nombre)
///   gastos   (id, grupo_id, concepto, importe, pagador_id, fecha, categoria)
///   partes   (gasto_id, miembro_id, importe)   -> cuánto le toca a cada uno
///   pagos    (id, grupo_id, de_id, a_id, importe, fecha)
/// Importes en céntimos (INTEGER) y fechas en milisegundos desde 1970.
class BaseDatos {
  BaseDatos._();
  static final BaseDatos instancia = BaseDatos._();

  /// Cambia cada vez que se modifica algo; las pantallas lo escuchan para
  /// recargarse solas.
  final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final ruta = join(await getDatabasesPath(), 'saldado.db');
    _db = await openDatabase(
      ruta,
      version: 1,
      // Activa las claves foráneas: al borrar un grupo se borra todo lo suyo.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE grupos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            moneda TEXT NOT NULL,
            creado INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE miembros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grupo_id INTEGER NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
            nombre TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE gastos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grupo_id INTEGER NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
            concepto TEXT NOT NULL,
            importe INTEGER NOT NULL,
            pagador_id INTEGER NOT NULL REFERENCES miembros(id),
            fecha INTEGER NOT NULL,
            categoria TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE partes (
            gasto_id INTEGER NOT NULL REFERENCES gastos(id) ON DELETE CASCADE,
            miembro_id INTEGER NOT NULL REFERENCES miembros(id),
            importe INTEGER NOT NULL,
            PRIMARY KEY (gasto_id, miembro_id)
          )''');
        await db.execute('''
          CREATE TABLE pagos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grupo_id INTEGER NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
            de_id INTEGER NOT NULL REFERENCES miembros(id),
            a_id INTEGER NOT NULL REFERENCES miembros(id),
            importe INTEGER NOT NULL,
            fecha INTEGER NOT NULL
          )''');
      },
    );
    return _db!;
  }

  void _avisar() => cambios.value++;

  // ---------------------------------------------------------------- Grupos

  /// Grupos con su número de miembros y total gastado, del más nuevo al más viejo.
  Future<List<ResumenGrupo>> resumenGrupos() async {
    final db = await _database;
    final filas = await db.rawQuery('''
      SELECT g.*,
        (SELECT COUNT(*) FROM miembros m WHERE m.grupo_id = g.id) AS num_miembros,
        (SELECT COALESCE(SUM(importe), 0) FROM gastos x WHERE x.grupo_id = g.id) AS total
      FROM grupos g
      ORDER BY g.creado DESC''');
    return filas
        .map((f) => ResumenGrupo(
              Grupo.desdeMapa(f),
              f['num_miembros'] as int,
              f['total'] as int,
            ))
        .toList();
  }

  /// Crea un grupo con sus miembros y devuelve su id.
  Future<int> crearGrupo(String nombre, String moneda, List<String> miembros) async {
    final db = await _database;
    final id = await db.transaction((txn) async {
      final grupoId = await txn.insert(
        'grupos',
        Grupo(nombre: nombre, moneda: moneda, creado: DateTime.now()).aMapa(),
      );
      for (final m in miembros) {
        await txn.insert('miembros', {'grupo_id': grupoId, 'nombre': m});
      }
      return grupoId;
    });
    _avisar();
    return id;
  }

  Future<void> actualizarGrupo(int id, String nombre, String moneda) async {
    await (await _database)
        .update('grupos', {'nombre': nombre, 'moneda': moneda}, where: 'id = ?', whereArgs: [id]);
    _avisar();
  }

  Future<void> borrarGrupo(int id) async {
    await (await _database).delete('grupos', where: 'id = ?', whereArgs: [id]);
    _avisar();
  }

  /// Carga un grupo completo: miembros, gastos (con sus partes) y pagos.
  /// Devuelve null si el grupo ya no existe.
  Future<DatosGrupo?> cargarGrupo(int id) async {
    final db = await _database;
    final filasGrupo = await db.query('grupos', where: 'id = ?', whereArgs: [id]);
    if (filasGrupo.isEmpty) return null;

    final miembros = (await db.query('miembros',
            where: 'grupo_id = ?', whereArgs: [id], orderBy: 'id'))
        .map(Miembro.desdeMapa)
        .toList();

    final filasPartes = await db.rawQuery('''
      SELECT p.* FROM partes p JOIN gastos g ON g.id = p.gasto_id
      WHERE g.grupo_id = ?''', [id]);
    final partesPorGasto = <int, List<Parte>>{};
    for (final f in filasPartes) {
      partesPorGasto
          .putIfAbsent(f['gasto_id'] as int, () => [])
          .add(Parte(f['miembro_id'] as int, f['importe'] as int));
    }

    final gastos = (await db.query('gastos',
            where: 'grupo_id = ?', whereArgs: [id], orderBy: 'fecha DESC, id DESC'))
        .map((f) => Gasto(
              id: f['id'] as int,
              grupoId: f['grupo_id'] as int,
              concepto: f['concepto'] as String,
              importe: f['importe'] as int,
              pagadorId: f['pagador_id'] as int,
              fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
              categoria: Categoria.porNombre(f['categoria'] as String),
              partes: partesPorGasto[f['id'] as int] ?? const [],
            ))
        .toList();

    final pagos = (await db.query('pagos',
            where: 'grupo_id = ?', whereArgs: [id], orderBy: 'fecha DESC, id DESC'))
        .map(Pago.desdeMapa)
        .toList();

    return DatosGrupo(
      grupo: Grupo.desdeMapa(filasGrupo.first),
      miembros: miembros,
      gastos: gastos,
      pagos: pagos,
    );
  }

  // ---------------------------------------------------------------- Miembros

  Future<void> agregarMiembro(int grupoId, String nombre) async {
    await (await _database).insert('miembros', {'grupo_id': grupoId, 'nombre': nombre});
    _avisar();
  }

  Future<void> renombrarMiembro(int id, String nombre) async {
    await (await _database)
        .update('miembros', {'nombre': nombre}, where: 'id = ?', whereArgs: [id]);
    _avisar();
  }

  /// true si el miembro aparece en algún gasto o pago (entonces no se puede borrar).
  Future<bool> miembroEnUso(int id) async {
    final db = await _database;
    final r = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM gastos WHERE pagador_id = ?) +
        (SELECT COUNT(*) FROM partes WHERE miembro_id = ?) +
        (SELECT COUNT(*) FROM pagos WHERE de_id = ? OR a_id = ?) AS usos''', [id, id, id, id]);
    return (r.first['usos'] as int) > 0;
  }

  Future<void> borrarMiembro(int id) async {
    await (await _database).delete('miembros', where: 'id = ?', whereArgs: [id]);
    _avisar();
  }

  // ---------------------------------------------------------------- Gastos

  /// Inserta un gasto nuevo (id null) o reemplaza uno existente, con sus partes.
  /// Todo dentro de una transacción: o se guarda entero o no se guarda nada.
  Future<void> guardarGasto(Gasto gasto) async {
    final db = await _database;
    await db.transaction((txn) async {
      int gastoId;
      if (gasto.id == null) {
        gastoId = await txn.insert('gastos', gasto.aMapa());
      } else {
        gastoId = gasto.id!;
        await txn.update('gastos', gasto.aMapa(), where: 'id = ?', whereArgs: [gastoId]);
        await txn.delete('partes', where: 'gasto_id = ?', whereArgs: [gastoId]);
      }
      for (final p in gasto.partes) {
        await txn.insert('partes', {
          'gasto_id': gastoId,
          'miembro_id': p.miembroId,
          'importe': p.importe,
        });
      }
    });
    _avisar();
  }

  Future<void> borrarGasto(int id) async {
    await (await _database).delete('gastos', where: 'id = ?', whereArgs: [id]);
    _avisar();
  }

  // ---------------------------------------------------------------- Pagos

  /// Guarda un pago y devuelve su id (para poder deshacerlo).
  Future<int> registrarPago(Pago pago) async {
    final id = await (await _database).insert('pagos', pago.aMapa());
    _avisar();
    return id;
  }

  Future<void> borrarPago(int id) async {
    await (await _database).delete('pagos', where: 'id = ?', whereArgs: [id]);
    _avisar();
  }
}
