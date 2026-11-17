import 'package:flutter/material.dart';

import '../i18n.dart';
import '../logica/cuentas.dart';
import '../models/modelos.dart';
import '../tema.dart';

/// Círculo con la inicial del miembro. El color depende de su posición en el
/// grupo, así cada persona tiene siempre el mismo color.
class AvatarMiembro extends StatelessWidget {
  final String nombre;
  final int indice;
  final double tamano;

  const AvatarMiembro({super.key, required this.nombre, required this.indice, this.tamano = 40});

  @override
  Widget build(BuildContext context) {
    final color = Colores.avatares[indice % Colores.avatares.length];
    final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Text(
        inicial,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: tamano * 0.42),
      ),
    );
  }
}

/// Icono de categoría dentro de un cuadrado redondeado de su color.
class IconoCategoria extends StatelessWidget {
  final Categoria categoria;
  final double tamano;

  const IconoCategoria(this.categoria, {super.key, this.tamano = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: categoria.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(tamano * 0.3),
      ),
      child: Icon(categoria.icono, color: categoria.color, size: tamano * 0.52),
    );
  }
}

/// Saldo con color, signo y texto: "+12,50 €  le deben" / "−8,00 €  debe".
class TextoSaldo extends StatelessWidget {
  final int saldo;
  final Moneda moneda;
  final bool grande;

  const TextoSaldo({super.key, required this.saldo, required this.moneda, this.grande = false});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String etiqueta;
    if (saldo > 0) {
      color = Colores.aFavor;
      etiqueta = Tx.leDeben;
    } else if (saldo < 0) {
      color = Colores.enContra;
      etiqueta = Tx.debe;
    } else {
      color = Colores.textoSecundario;
      etiqueta = Tx.enPaz;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatearImporte(saldo, moneda, conSigno: true),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: grande ? 20 : 16,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(etiqueta, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

/// Logo de la app (asset generado a partir de assets/icon/logo_saldado.svg).
class LogoSaldado extends StatelessWidget {
  final double tamano;

  const LogoSaldado({super.key, this.tamano = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: tamano,
      height: tamano,
      semanticLabel: 'Saldado',
    );
  }
}

/// Mensaje centrado para listas vacías.
class EstadoVacio extends StatelessWidget {
  final Widget icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icono,
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colores.tinta,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.textoSecundario, height: 1.5),
            ),
            if (accion != null) ...[const SizedBox(height: 24), accion!],
          ],
        ),
      ),
    );
  }
}
