import 'package:flutter/material.dart';

import '../data/base_datos.dart';
import '../i18n.dart';
import '../logica/cuentas.dart';
import '../logica/textos.dart';
import '../models/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

enum _ModoReparto { igual, exacto }

/// Añadir un gasto nuevo o editar [gasto] si se pasa.
class EditarGastoScreen extends StatefulWidget {
  final DatosGrupo datos;
  final Gasto? gasto;

  const EditarGastoScreen({super.key, required this.datos, this.gasto});

  @override
  State<EditarGastoScreen> createState() => _EditarGastoScreenState();
}

class _EditarGastoScreenState extends State<EditarGastoScreen> {
  final _db = BaseDatos.instancia;
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _concepto;
  late final TextEditingController _importe;
  late int _pagadorId;
  late DateTime _fecha;
  late Categoria _categoria;
  _ModoReparto _modo = _ModoReparto.igual;
  final Set<int> _participantes = {};
  final Map<int, TextEditingController> _exactos = {};
  bool _guardando = false;

  List<Miembro> get _miembros => widget.datos.miembros;
  Moneda get _moneda => widget.datos.grupo.datosMoneda;
  bool get _editando => widget.gasto != null;

  /// En inglés el símbolo de la moneda va siempre delante (€12.50).
  bool get _simboloDelante => _moneda.simboloDelante || !Idioma.es;

  /// Símbolo delante del número, con espacio si es de varias letras ("CHF 12.50").
  String? get _prefijo => _simboloDelante
      ? (_moneda.simbolo.length > 1 ? '${_moneda.simbolo} ' : _moneda.simbolo)
      : null;

  /// Importe escrito en céntimos (0 si aún no es válido).
  int get _total => parsearImporte(_importe.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final g = widget.gasto;
    _concepto = TextEditingController(text: g?.concepto ?? '');
    _importe = TextEditingController(
      text: g == null ? '' : formatearImporte(g.importe, _moneda).replaceAll(RegExp(r'[^0-9.,]'), ''),
    );
    _pagadorId = g?.pagadorId ?? _miembros.first.id!;
    _fecha = g?.fecha ?? DateTime.now();
    _categoria = g?.categoria ?? Categoria.comida;

    for (final m in _miembros) {
      _exactos[m.id!] = TextEditingController();
    }

    if (g == null) {
      _participantes.addAll(_miembros.map((m) => m.id!));
    } else {
      _participantes.addAll(g.partes.map((p) => p.miembroId));
      for (final p in g.partes) {
        _exactos[p.miembroId]?.text =
            formatearImporte(p.importe, _moneda).replaceAll(RegExp(r'[^0-9.,]'), '');
      }
      // Si las partes coinciden con un reparto a partes iguales, se muestra así
      final ordenados = _miembros.where((m) => _participantes.contains(m.id)).toList();
      final cuotas = repartirIgual(g.importe, ordenados.length);
      final esIgual = [
        for (var i = 0; i < ordenados.length; i++)
          g.partes.any((p) => p.miembroId == ordenados[i].id && p.importe == cuotas[i])
      ].every((x) => x);
      _modo = esIgual ? _ModoReparto.igual : _ModoReparto.exacto;
    }
  }

  @override
  void dispose() {
    _concepto.dispose();
    _importe.dispose();
    for (final c in _exactos.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Partes del reparto con los datos actuales del formulario.
  List<Parte> _partes() {
    if (_modo == _ModoReparto.igual) {
      final ids = [for (final m in _miembros) if (_participantes.contains(m.id)) m.id!];
      final cuotas = repartirIgual(_total, ids.length);
      return [for (var i = 0; i < ids.length; i++) Parte(ids[i], cuotas[i])];
    }
    return [
      for (final m in _miembros)
        if ((parsearImporte(_exactos[m.id]!.text) ?? 0) > 0)
          Parte(m.id!, parsearImporte(_exactos[m.id]!.text)!)
    ];
  }

  int get _sumaExactos =>
      _miembros.fold(0, (s, m) => s + (parsearImporte(_exactos[m.id]!.text) ?? 0));

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null) {
      // Se conserva la hora para que el orden de la lista sea natural
      setState(() => _fecha = DateTime(
            elegida.year,
            elegida.month,
            elegida.day,
            _fecha.hour,
            _fecha.minute,
          ));
    }
  }

  void _aviso(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final total = _total;
    final partes = _partes();
    if (partes.isEmpty) {
      _aviso(Tx.eligeAlguien);
      return;
    }
    if (_modo == _ModoReparto.exacto) {
      for (final m in _miembros) {
        final texto = _exactos[m.id]!.text.trim();
        if (texto.isNotEmpty && parsearImporte(texto) == null) {
          _aviso(Tx.revisaImporte(m.nombre));
          return;
        }
      }
    }
    if (_modo == _ModoReparto.exacto && _sumaExactos != total) {
      _aviso(Tx.debenSumar(formatearImporte(total, _moneda)));
      return;
    }
    setState(() => _guardando = true);
    try {
      await _db.guardarGasto(Gasto(
        id: widget.gasto?.id,
        grupoId: widget.datos.grupo.id!,
        concepto: _concepto.text.trim(),
        importe: total,
        pagadorId: _pagadorId,
        fecha: _fecha,
        categoria: _categoria,
        partes: partes,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error al guardar el gasto: $e');
      if (mounted) {
        setState(() => _guardando = false);
        _aviso(Tx.errorGuardarGasto);
      }
    }
  }

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(Tx.borrarGastoTitulo),
        content: Text(Tx.borrarGastoTexto(widget.gasto!.concepto)),
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
    if (ok != true) return;
    await _db.borrarGasto(widget.gasto!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const titulo = TextStyle(color: Colores.tinta, fontWeight: FontWeight.w800, fontSize: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? Tx.editarGasto : Tx.nuevoGasto),
        actions: [
          if (_editando)
            IconButton(
              tooltip: Tx.borrarGasto,
              onPressed: _borrar,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            TextFormField(
              controller: _concepto,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: Tx.concepto,
                hintText: Tx.conceptoEjemplo,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? Tx.escribeQueEs : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _importe,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: Tx.importe,
                hintText: Tx.importeEjemplo,
                suffixText: _simboloDelante ? null : _moneda.simbolo,
                prefixText: _prefijo,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final c = parsearImporte(v ?? '');
                if (c == null) return Tx.importeNoValido;
                if (c == 0) return Tx.importeCero;
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _pagadorId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: Tx.pagadoPor),
                    items: [
                      for (final m in _miembros)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nombre, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _pagadorId = v ?? _pagadorId),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(fechaCorta(_fecha)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(Tx.categoria, style: titulo),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in Categoria.values)
                  ChoiceChip(
                    avatar: Icon(c.icono, size: 18, color: c.color),
                    label: Text(c.nombre),
                    selected: _categoria == c,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(Tx.comoSeReparte, style: titulo),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_ModoReparto>(
                segments: [
                  ButtonSegment(
                    value: _ModoReparto.igual,
                    label: Text(Tx.partesIguales),
                    icon: const Icon(Icons.balance_rounded),
                  ),
                  ButtonSegment(
                    value: _ModoReparto.exacto,
                    label: Text(Tx.importesExactos),
                    icon: const Icon(Icons.edit_note_rounded),
                  ),
                ],
                selected: {_modo},
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
            ),
            const SizedBox(height: 12),
            if (_modo == _ModoReparto.igual) _repartoIgual() else _repartoExacto(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _guardando ? null : _guardar,
          child: Text(_editando ? Tx.guardarCambios : Tx.anadirGasto),
        ),
      ),
    );
  }

  Widget _repartoIgual() {
    final cuotas = {for (final p in _partes()) p.miembroId: p.importe};
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < _miembros.length; i++)
            CheckboxListTile(
              value: _participantes.contains(_miembros[i].id),
              onChanged: (marcado) => setState(() {
                if (marcado == true) {
                  _participantes.add(_miembros[i].id!);
                } else {
                  _participantes.remove(_miembros[i].id!);
                }
              }),
              secondary: AvatarMiembro(nombre: _miembros[i].nombre, indice: i, tamano: 36),
              title: Text(_miembros[i].nombre),
              subtitle: cuotas.containsKey(_miembros[i].id)
                  ? Text(formatearImporte(cuotas[_miembros[i].id]!, _moneda))
                  : Text(Tx.noParticipa),
            ),
        ],
      ),
    );
  }

  Widget _repartoExacto() {
    final total = _total;
    final asignado = _sumaExactos;
    final diferencia = total - asignado;
    final String estado;
    final Color color;
    if (diferencia == 0) {
      estado = Tx.cuadra(formatearImporte(total, _moneda));
      color = Colores.aFavor;
    } else if (diferencia > 0) {
      estado = Tx.faltan(formatearImporte(diferencia, _moneda));
      color = Colores.enContra;
    } else {
      estado = Tx.sobran(formatearImporte(-diferencia, _moneda));
      color = Colores.enContra;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < _miembros.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    AvatarMiembro(nombre: _miembros[i].nombre, indice: i, tamano: 36),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_miembros[i].nombre)),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _exactos[_miembros[i].id],
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: Tx.importeEjemplo,
                          suffixText: _simboloDelante ? null : _moneda.simbolo,
                          prefixText: _prefijo,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(
                  diferencia == 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(estado, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
