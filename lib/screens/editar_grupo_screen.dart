import 'package:flutter/material.dart';

import '../data/base_datos.dart';
import '../i18n.dart';
import '../models/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Una fila de miembro en el formulario.
class _FilaMiembro {
  final int? id; // null si es nuevo
  final String nombreOriginal;
  final TextEditingController controlador;

  _FilaMiembro({this.id, String nombre = ''})
      : nombreOriginal = nombre,
        controlador = TextEditingController(text: nombre);
}

/// Crear un grupo nuevo o editar uno existente ([existente]).
/// Al guardar devuelve (con Navigator.pop) el id del grupo.
class EditarGrupoScreen extends StatefulWidget {
  final DatosGrupo? existente;

  const EditarGrupoScreen({super.key, this.existente});

  @override
  State<EditarGrupoScreen> createState() => _EditarGrupoScreenState();
}

class _EditarGrupoScreenState extends State<EditarGrupoScreen> {
  final _db = BaseDatos.instancia;
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late String _moneda;
  final List<_FilaMiembro> _filas = [];
  final List<int> _borrados = [];
  bool _guardando = false;

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _nombre = TextEditingController(text: e?.grupo.nombre ?? '');
    _moneda = e?.grupo.moneda ?? 'EUR';
    if (e != null) {
      _filas.addAll(e.miembros.map((m) => _FilaMiembro(id: m.id, nombre: m.nombre)));
    } else {
      // Un grupo nuevo empieza con dos huecos
      _filas.addAll([_FilaMiembro(), _FilaMiembro()]);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    for (final f in _filas) {
      f.controlador.dispose();
    }
    super.dispose();
  }

  void _agregarFila() => setState(() => _filas.add(_FilaMiembro()));

  Future<void> _quitarFila(_FilaMiembro fila) async {
    // Un miembro que ya aparece en gastos o pagos no se puede quitar:
    // las cuentas dejarían de cuadrar.
    if (fila.id != null && await _db.miembroEnUso(fila.id!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Tx.noSePuedeQuitar(fila.nombreOriginal)),
      ));
      return;
    }
    // La pantalla puede haberse cerrado, o la fila ya quitada (doble toque)
    if (!mounted || !_filas.contains(fila)) return;
    setState(() {
      _filas.remove(fila);
      if (fila.id != null) _borrados.add(fila.id!);
    });
    // Se libera cuando el campo ya ha desaparecido de la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => fila.controlador.dispose());
  }

  String? _validarMiembros() {
    final nombres = _filas.map((f) => f.controlador.text.trim()).where((n) => n.isNotEmpty).toList();
    if (nombres.length < 2) return Tx.minimoDos;
    final unicos = nombres.map((n) => n.toLowerCase()).toSet();
    if (unicos.length != nombres.length) return Tx.nombreRepetido;
    return null;
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final error = _validarMiembros();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _guardando = true);
    try {
      await _guardarEnBaseDatos();
    } catch (e) {
      debugPrint('Error al guardar el grupo: $e');
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Tx.errorGuardarGrupo)));
      }
    }
  }

  Future<void> _guardarEnBaseDatos() async {
    final nombre = _nombre.text.trim();

    int id;
    if (!_editando) {
      final nombres = [
        for (final f in _filas)
          if (f.controlador.text.trim().isNotEmpty) f.controlador.text.trim()
      ];
      id = await _db.crearGrupo(nombre, _moneda, nombres);
    } else {
      id = widget.existente!.grupo.id!;
      await _db.actualizarGrupo(id, nombre, _moneda);
      for (final borrado in _borrados) {
        await _db.borrarMiembro(borrado);
      }
      for (final f in _filas) {
        final texto = f.controlador.text.trim();
        if (f.id == null) {
          if (texto.isNotEmpty) await _db.agregarMiembro(id, texto);
        } else if (texto.isNotEmpty && texto != f.nombreOriginal) {
          await _db.renombrarMiembro(f.id!, texto);
        }
      }
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? Tx.editarGrupo : Tx.nuevoGrupo)),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: Tx.nombreGrupo,
                hintText: Tx.nombreGrupoEjemplo,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? Tx.ponleNombre : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _moneda,
              decoration: InputDecoration(labelText: Tx.moneda),
              items: [
                for (final m in Moneda.lista)
                  DropdownMenuItem(value: m.codigo, child: Text('${m.nombre} (${m.simbolo})')),
              ],
              onChanged: (v) => setState(() => _moneda = v ?? _moneda),
            ),
            const SizedBox(height: 28),
            Text(
              Tx.tituloPersonas,
              style: const TextStyle(color: Colores.tinta, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              Tx.explicacionPersonas,
              style: const TextStyle(color: Colores.textoSecundario),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _filas.length; i++)
              Padding(
                key: ObjectKey(_filas[i]),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _filas[i].controlador,
                      builder: (_, valor, __) => AvatarMiembro(nombre: valor.text, indice: i),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _filas[i].controlador,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(hintText: Tx.persona(i + 1)),
                        // Alguien que ya existe no se puede dejar sin nombre
                        validator: (v) =>
                            (_filas[i].id != null && (v ?? '').trim().isEmpty)
                                ? Tx.escribeNombreOQuita
                                : null,
                      ),
                    ),
                    IconButton(
                      tooltip: Tx.quitar,
                      onPressed: _filas.length <= 2 ? null : () => _quitarFila(_filas[i]),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _agregarFila,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(Tx.anadirPersona),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _guardando ? null : _guardar,
          child: Text(_editando ? Tx.guardarCambios : Tx.crearGrupo),
        ),
      ),
    );
  }
}
