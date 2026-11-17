import 'package:flutter/material.dart';

import '../data/base_datos.dart';
import '../i18n.dart';
import '../logica/cuentas.dart';
import '../models/modelos.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'acerca_de.dart';
import 'editar_grupo_screen.dart';
import 'grupo_screen.dart';

/// Pantalla principal: lista de grupos (un viaje, el piso, una cena...).
class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final _db = BaseDatos.instancia;
  List<ResumenGrupo>? _grupos;

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
    final grupos = await _db.resumenGrupos();
    if (mounted) setState(() => _grupos = grupos);
  }

  Future<void> _nuevoGrupo() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const EditarGrupoScreen()),
    );
    // Al crear un grupo, se entra directamente en él
    if (id != null && mounted) _abrir(id);
  }

  void _abrir(int id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GrupoScreen(grupoId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            LogoSaldado(tamano: 34),
            SizedBox(width: 12),
            Text('Saldado'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: Tx.acercaDe,
            onPressed: () => mostrarAcercaDe(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: grupos == null || grupos.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _nuevoGrupo,
              icon: const Icon(Icons.group_add_rounded),
              label: Text(Tx.nuevoGrupo),
            ),
      body: grupos == null
          ? const Center(child: CircularProgressIndicator())
          : grupos.isEmpty
              ? EstadoVacio(
                  icono: const LogoSaldado(tamano: 96),
                  titulo: Tx.bienvenidaTitulo,
                  texto: Tx.bienvenidaTexto,
                  accion: FilledButton.icon(
                    onPressed: _nuevoGrupo,
                    icon: const Icon(Icons.group_add_rounded),
                    label: Text(Tx.crearPrimerGrupo),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: grupos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TarjetaGrupo(
                    resumen: grupos[i],
                    indice: i,
                    onTap: () => _abrir(grupos[i].grupo.id!),
                  ),
                ),
    );
  }
}

class _TarjetaGrupo extends StatelessWidget {
  final ResumenGrupo resumen;
  final int indice;
  final VoidCallback onTap;

  const _TarjetaGrupo({required this.resumen, required this.indice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final g = resumen.grupo;
    final personas = Tx.personas(resumen.numMiembros);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarMiembro(nombre: g.nombre, indice: indice, tamano: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colores.tinta,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(personas, style: const TextStyle(color: Colores.textoSecundario)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatearImporte(resumen.total, g.datosMoneda),
                    style: const TextStyle(
                      color: Colores.tinta,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(Tx.gastado,
                      style: const TextStyle(color: Colores.textoSecundario, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
