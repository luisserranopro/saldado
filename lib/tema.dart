import 'package:flutter/material.dart';

/// Colores de Saldado (los mismos del logo).
class Colores {
  static const verde = Color(0xFF0E9F7E);
  static const verdeOscuro = Color(0xFF0B7A62);
  static const menta = Color(0xFF9BF2D3);
  static const fondo = Color(0xFFF3F7F5);
  static const tinta = Color(0xFF10231F);
  static const textoSecundario = Color(0xFF4B635D);
  static const borde = Color(0xFFDDE6E3);

  /// Saldo a favor (le deben) y en contra (debe). Además del color, el texto
  /// lleva signo y una etiqueta, para quien no distingue bien rojo y verde.
  static const aFavor = Color(0xFF0B7A62);
  static const enContra = Color(0xFFC2410C);

  /// Colores para los avatares de los miembros.
  static const avatares = [
    Color(0xFF0E9F7E),
    Color(0xFF3F8EFC),
    Color(0xFFE8833A),
    Color(0xFF7B61FF),
    Color(0xFFE5487A),
    Color(0xFF8C6D4F),
    Color(0xFF0891B2),
    Color(0xFF65A30D),
  ];
}

ThemeData temaSaldado() {
  final esquema = ColorScheme.fromSeed(seedColor: Colores.verde).copyWith(
    primary: Colores.verde,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colores.tinta,
  );
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Colores.borde),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colores.tinta,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colores.borde),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: Colores.verde, width: 2),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colores.verde,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
