import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/base_datos.dart';
import '../i18n.dart';
import '../logica/cuentas.dart';
import '../logica/textos.dart';
import '../models/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'editar_gasto_screen.dart';
import 'editar_grupo_screen.dart';

/// Un grupo: lista de gastos y pagos, y pestaña de saldos.
class GrupoScreen extends StatefulWidget {
  final int grupoId;

  const GrupoScreen({super.key, required this.grupoId});

  @override
  State<GrupoScreen> createState() => _GrupoScreenState();
}

class _GrupoScreenState extends State<GrupoScreen> {
  final _db = BaseDatos.instancia;
  DatosGrupo? _datos;

  @override
  void initState() {
    super.initState();
    _cargar();
    _db.cambios.addListener(_cargar);
  }

  @override
  void dispose() {
    _db.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final datos = await _db.cargarGrupo(widget.grupoId);
    if (!mounted) return;
    if (datos == null) {
      // El grupo se ha borrado: volvemos a la lista
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      return;
    }
    setState(() => _datos = datos);
  }

  void _abrirGasto({Gasto? gasto}) {
    final datos = _datos;
    if (datos == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditarGastoScreen(datos: datos, gasto: gasto),
    ));
  }

  Future<void> _editarGrupo() async {
    final datos = _datos;
    if (datos == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditarGrupoScreen(existente: datos),
    ));
  }

  Future<void> _borrarGrupo() async {
    final datos = _datos;
    if (datos == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(Tx.borrarGrupoTitulo(datos.grupo.nombre)),
        content: Text(Tx.borrarGrupoTexto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: Text(Tx.cancelar)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colores.enContra),
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(Tx.borrar),
          ),
        ],
      ),
    );
    if (ok == true) await _db.borrarGrupo(datos.grupo.id!);
  }

  void _compartir() {
    final datos = _datos;
    if (datos == null) return;
    final texto = textoResumen(datos);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_rounded, color: Colores.verde),
              title: Text(Tx.enviarWhatsApp),
              onTap: () {
                Navigator.pop(contexto);
                launchUrl(
                  Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colores.verde),
              title: Text(Tx.copiarResumen),
              subtitle: Text(Tx.copiarResumenDetalle),
              onTap: () async {
                Navigator.pop(contexto);
                await Clipboard.setData(ClipboardData(text: texto));
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(Tx.resumenCopiado)));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = _datos;
    if (datos == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(datos.grupo.nombre),
          actions: [
            IconButton(
              tooltip: Tx.compartirResumen,
              onPressed: _compartir,
              icon: const Icon(Icons.ios_share_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: Tx.masOpciones,
              onSelected: (opcion) {
                if (opcion == 'editar') _editarGrupo();
                if (opcion == 'borrar') _borrarGrupo();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'editar', child: Text(Tx.editarGrupoYPersonas)),
                PopupMenuItem(value: 'borrar', child: Text(Tx.borrarGrupo)),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor: Colores.verdeOscuro,
            indicatorColor: Colores.verde,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [Tab(text: Tx.pestanaGastos), Tab(text: Tx.pestanaSaldos)],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirGasto(),
          icon: const Icon(Icons.add_rounded),
          label: Text(Tx.anadirGasto),
        ),
        body: TabBarView(
          children: [
            _PestanaGastos(datos: datos, abrirGasto: (g) => _abrirGasto(gasto: g)),
            _PestanaSaldos(datos: datos),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Pestaña Gastos
// ======================================================================

/// Un elemento de la lista: o un gasto o un pago.
class _Movimiento {
  final Gasto? gasto;
  final Pago? pago;

  _Movimiento.gasto(Gasto this.gasto) : pago = null;
  _Movimiento.pago(Pago this.pago) : gasto = null;

  DateTime get fecha => gasto?.fecha ?? pago!.fecha;
}

class _PestanaGastos extends StatelessWidget {
  final DatosGrupo datos;
  final ValueChanged<Gasto> abrirGasto;

  const _PestanaGastos({required this.datos, required this.abrirGasto});

  @override
  Widget build(BuildContext context) {
    final moneda = datos.grupo.datosMoneda;
    final movimientos = [
      ...datos.gastos.map(_Movimiento.gasto),
      ...datos.pagos.map(_Movimiento.pago),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (movimientos.isEmpty) {
      return EstadoVacio(
        icono: const Icon(Icons.receipt_long_rounded, size: 64, color: Colores.menta),
        titulo: Tx.sinGastosTitulo,
        texto: Tx.sinGastosTexto,
      );
    }

    // Lista plana con cabeceras de día intercaladas
    final filas = <Widget>[
      _ResumenTotal(datos: datos),
    ];
    String? diaAnterior;
    for (final m in movimientos) {
      final dia = cabeceraDia(m.fecha);
      if (dia != diaAnterior) {
        filas.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            dia,
            style: const TextStyle(
              color: Colores.textoSecundario,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ));
        diaAnterior = dia;
      }
      filas.add(m.gasto != null
          ? _FilaGasto(datos: datos, gasto: m.gasto!, moneda: moneda, onTap: abrirGasto)
          : _FilaPago(datos: datos, pago: m.pago!, moneda: moneda));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: filas);
  }
}

class _ResumenTotal extends StatelessWidget {
  final DatosGrupo datos;

  const _ResumenTotal({required this.datos});

  @override
  Widget build(BuildContext context) {
    final n = datos.gastos.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colores.verde, Colores.verdeOscuro]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Tx.totalGastado, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  formatearImporte(datos.totalGastado, datos.grupo.datosMoneda),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Tx.numGastos(n),
            style: const TextStyle(color: Colores.menta, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilaGasto extends StatelessWidget {
  final DatosGrupo datos;
  final Gasto gasto;
  final Moneda moneda;
  final ValueChanged<Gasto> onTap;

  const _FilaGasto({
    required this.datos,
    required this.gasto,
    required this.moneda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final todos = gasto.partes.length == datos.miembros.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => onTap(gasto),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: IconoCategoria(gasto.categoria),
          title: Text(
            gasto.concepto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colores.tinta),
          ),
          subtitle: Text(Tx.pagoYReparto(datos.nombreDe(gasto.pagadorId), todos, gasto.partes.length)),
          trailing: Text(
            formatearImporte(gasto.importe, moneda),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colores.tinta,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaPago extends StatelessWidget {
  final DatosGrupo datos;
  final Pago pago;
  final Moneda moneda;

  const _FilaPago({required this.datos, required this.pago, required this.moneda});

  Future<void> _borrar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(Tx.borrarPagoTitulo),
        content: Text(
          '${datos.nombreDe(pago.deId)} → ${datos.nombreDe(pago.aId)}: '
          '${formatearImporte(pago.importe, moneda)}.\n'
          '${Tx.borrarPagoTexto}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: Text(Tx.cancelar)),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: Text(Tx.borrar)),
        ],
      ),
    );
    if (ok == true) await BaseDatos.instancia.borrarPago(pago.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colores.menta.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _borrar(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.swap_horiz_rounded, color: Colores.verdeOscuro),
          ),
          title: Text(
            Tx.pagoA(datos.nombreDe(pago.deId), datos.nombreDe(pago.aId)),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colores.tinta),
          ),
          subtitle: Text(Tx.pagoParaSaldar),
          trailing: Text(
            formatearImporte(pago.importe, moneda),
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colores.verdeOscuro),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Pestaña Saldos
// ======================================================================

class _PestanaSaldos extends StatefulWidget {
  final DatosGrupo datos;

  const _PestanaSaldos({required this.datos});

  @override
  State<_PestanaSaldos> createState() => _PestanaSaldosState();
}

class _PestanaSaldosState extends State<_PestanaSaldos> {
  // Evita registrar dos veces el mismo pago con un doble toque
  bool _registrando = false;

  DatosGrupo get datos => widget.datos;

  Future<void> _marcarPagado(BuildContext context, Transferencia t) async {
    if (_registrando) return;
    _registrando = true;
    final db = BaseDatos.instancia;
    final int id;
    try {
      id = await db.registrarPago(Pago(
      grupoId: datos.grupo.id!,
      deId: t.deId,
      aId: t.aId,
      importe: t.importe,
      fecha: DateTime.now(),
    ));
    } finally {
      _registrando = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(Tx.pagoRegistrado(datos.nombreDe(t.deId), datos.nombreDe(t.aId))),
        action: SnackBarAction(label: Tx.deshacer, onPressed: () => db.borrarPago(id)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final moneda = datos.grupo.datosMoneda;
    final saldos = calcularSaldos(datos.miembros, datos.gastos, datos.pagos);
    final totales = calcularTotales(datos.miembros, datos.gastos);
    final transferencias = liquidar(saldos);
    int indiceDe(int id) => datos.miembros.indexWhere((m) => m.id == id);

    const estiloTitulo = TextStyle(
      color: Colores.tinta,
      fontWeight: FontWeight.w800,
      fontSize: 18,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ---------- Cómo saldar ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(Tx.comoSaldar, style: estiloTitulo),
        ),
        if (transferencias.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const LogoSaldado(tamano: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      datos.gastos.isEmpty
                          ? Tx.sinGastosSaldos
                          : Tx.todoSaldado,
                      style: const TextStyle(
                        color: Colores.tinta,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              Tx.conPagos(transferencias.length),
              style: const TextStyle(color: Colores.textoSecundario),
            ),
          ),
          for (final t in transferencias)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AvatarMiembro(nombre: datos.nombreDe(t.deId), indice: indiceDe(t.deId)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, color: Colores.textoSecundario),
                          ),
                          AvatarMiembro(nombre: datos.nombreDe(t.aId), indice: indiceDe(t.aId)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Tx.pagaA(datos.nombreDe(t.deId), datos.nombreDe(t.aId)),
                              style: const TextStyle(
                                color: Colores.tinta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            formatearImporte(t.importe, moneda),
                            style: const TextStyle(
                              color: Colores.tinta,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _marcarPagado(context, t),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: Text(Tx.marcarPagado),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],

        // ---------- Saldo de cada persona ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
          child: Text(Tx.saldoPersona, style: estiloTitulo),
        ),
        for (var i = 0; i < datos.miembros.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    AvatarMiembro(nombre: datos.miembros[i].nombre, indice: i),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            datos.miembros[i].nombre,
                            style: const TextStyle(
                              color: Colores.tinta,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Tx.pagoYParte(
                              formatearImporte(totales[datos.miembros[i].id]?.pagado ?? 0, moneda),
                              formatearImporte(totales[datos.miembros[i].id]?.consumido ?? 0, moneda),
                            ),
                            style: const TextStyle(color: Colores.textoSecundario, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    TextoSaldo(saldo: saldos[datos.miembros[i].id] ?? 0, moneda: moneda),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
