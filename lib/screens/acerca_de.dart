import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Dirección pública de la política de privacidad (la pide Google Play).
/// Si el repositorio tiene otro nombre o usuario, cámbiala aquí.
const urlPrivacidad =
    'https://github.com/luisserranopro/saldado/blob/main/docs/politica-privacidad.md';

/// Ventana "Acerca de": versión, privacidad y licencias de código abierto
/// (showAboutDialog trae el botón de licencias ya hecho).
void mostrarAcercaDe(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Saldado',
    applicationVersion: '1.0.0',
    applicationIcon: const LogoSaldado(tamano: 56),
    children: [
      Text(
        '${Tx.lema}\n\n${Tx.textoAcercaDe}',
        style: const TextStyle(height: 1.5),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colores.verde),
          onPressed: () =>
              launchUrl(Uri.parse(urlPrivacidad), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.privacy_tip_outlined, size: 18),
          label: Text(Tx.politicaPrivacidad),
        ),
      ),
    ],
  );
}
