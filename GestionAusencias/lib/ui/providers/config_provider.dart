import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider extends ChangeNotifier {
  String? _backgroundImage;

  // Lista de fondos predefinidos (URLs de imágenes de alta calidad)
  final List<String> _wallpapers = [
    'assets/wallpapers/forest_road.png',
    'assets/wallpapers/dark_forest_road.png',
    'assets/wallpapers/autumn_mountains.jpg',
    'assets/wallpapers/mountain_lake.jpg',
    'https://i.pinimg.com/1200x/10/93/35/1093355c37a53cb8fca48df435418e79.jpg',
    'https://i.pinimg.com/1200x/9c/4a/1a/9c4a1a04330f0a7b2ae1f3d9b189f40d.jpg',
    'https://i.pinimg.com/1200x/87/d8/02/87d80227d335a4906251c266bc46bc0a.jpg',
    'https://i.pinimg.com/1200x/3e/ca/2f/3eca2ff1fd84d665cb8882ca0004307d.jpg',
    'https://i.pinimg.com/736x/21/14/79/211479f8a28b42621bc4a9c20e8910d.jpg',
    'https://i.pinimg.com/736x/ae/c7/0a/aec70ad497b05a56d70f0d3337803eaf.jpg',
  ];

  String? get backgroundImage => _backgroundImage;
  List<String> get wallpapers => _wallpapers;

  ImageProvider? get backgroundImageProvider {
    if (_backgroundImage == null) return null;
    if (_backgroundImage!.startsWith('assets/')) {
      return AssetImage(_backgroundImage!);
    }
    return NetworkImage(_backgroundImage!);
  }

  ConfigProvider() {
    _loadPreferences();
  }

  Locale _appLocale = const Locale('es');
  Locale get appLocale => _appLocale;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg = prefs.getString('backgroundImage');
    final savedLang = prefs.getString('app_language');

    // Load Background
    if (savedBg != null && !_wallpapers.contains(savedBg)) {
      await prefs.remove('backgroundImage');
      _backgroundImage = null;
    } else {
      _backgroundImage = savedBg;
    }

    // Load Language
    if (savedLang != null) {
      _appLocale = Locale(savedLang);
    }

    // Load Theme
    final savedTheme = prefs.getString('app_theme');
    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    notifyListeners();
  }

  Future<void> setWallpaper(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null) {
      await prefs.remove('backgroundImage');
    } else {
      await prefs.setString('backgroundImage', url);
    }
    _backgroundImage = url;
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    _appLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString('app_theme', modeStr);
    notifyListeners();
  }
}
