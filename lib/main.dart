import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/grupos_screen.dart';
import 'i18n.dart';
import 'tema.dart';

void main() {
  // En el navegador, SQLite funciona con WebAssembly (sqflite_common_ffi_web).
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const SaldadoApp());
}

class SaldadoApp extends StatelessWidget {
  const SaldadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saldado',
      debugShowCheckedModeBanner: false,
      theme: temaSaldado(),
      // Textos de Flutter (calendario, "Cancelar"…) en el idioma del móvil.
      // Los de la app están en lib/i18n.dart.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('es')],
      // El mismo idioma que los textos de la app (español o, si no, inglés)
      locale: Locale(Idioma.es ? 'es' : 'en'),
      home: const GruposScreen(),
    );
  }
}
