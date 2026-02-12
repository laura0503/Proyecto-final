import 'package:flutter/material.dart';

//esto para definir colores y temas de lo que va a ser la app, para luego en los otros dart, poner solamente la variable que se definió
class AppTheme {
  static const Color primary = Colors.deepPurple;
  static const Color fondoClaro = Colors.white;
  static const Color blancoSuperficie = Colors.white;
  static const Color textOscuro = Colors.black;
  static const Color naranjaPendientes = Colors.orange;

  static ThemeData get temaClaro {
    //para los widgets
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor:
          Colors.white, // todas las pantallas de la app sean blancas
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: blancoSuperficie,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textOscuro, fontSize: 10),
        bodySmall: TextStyle(color: Colors.blueGrey, fontSize: 8),
        displayLarge: TextStyle(
          color: textOscuro,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ), //titulos principales y ponnerlo en negrita
      ),
      cardTheme: CardThemeData(
        color: blancoSuperficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16,
          ), //pone las esquinas de las fotos redondas
          side: BorderSide(
            color: Colors.grey.shade200,
          ), //pone una linea de color gris
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
