import 'package:flutter/material.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'es': {
      'dashboard_title': 'San José Dashboard',
      'planning': 'Planning',
      'guardias': 'Guardias',
      'departamentos': 'Departamentos',
      'profesores': 'Profesores',
      'ajustes': 'Ajustes',
      'salir': 'Salir',
      'inicio': 'Inicio',
      'ausencias_hoy': 'Ausencias hoy',
      'pendientes': 'Pendientes',
      'areas': 'Áreas',
      'dptos_personal': 'Departamentos y Personal',
      'privacy_security': 'Privacidad y Seguridad',
      'personalization': 'Personalización',
      'privacy': 'Privacidad',
      'language': 'Idioma',
      'language_desc': 'Cambiar idioma de la aplicación',
      'theme': 'Tema',
      'theme_desc': 'Elige el modo claro, oscuro o del sistema',
      'theme_light': 'Claro',
      'theme_dark': 'Oscuro',
      'theme_system': 'Sistema',
      'change_password': 'Cambiar contraseña',
      'admin': 'Administrador',
      'horarios': 'Horarios',
    },
    'en': {
      'dashboard_title': 'San José Dashboard',
      'planning': 'Planning',
      'guardias': 'On Call',
      'departamentos': 'Departments',
      'profesores': 'Teachers',
      'ajustes': 'Settings',
      'salir': 'Logout',
      'inicio': 'Home',
      'ausencias_hoy': 'Absences today',
      'pendientes': 'Pending',
      'areas': 'Areas',
      'dptos_personal': 'Departments & Staff',
      'privacy_security': 'Privacy & Security',
      'personalization': 'Personalization',
      'privacy': 'Privacy',
      'language': 'Language',
      'language_desc': 'Change application language',
      'theme': 'Theme',
      'theme_desc': 'Choose light, dark, or system mode',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'System',
      'change_password': 'Change password',
      'admin': 'Admin',
      'horarios': 'Schedules',
    },
  };

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ??
        _localizedValues['es']?[key] ??
        key;
  }
}
