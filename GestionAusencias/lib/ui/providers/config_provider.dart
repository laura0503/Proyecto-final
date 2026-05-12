import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperItem {
  final String path;
  final String name;
  const WallpaperItem({required this.path, required this.name});
}

class ConfigProvider extends ChangeNotifier {
  String? _backgroundImage;

  final List<WallpaperItem> _wallpapers = const [
    WallpaperItem(path: 'assets/wallpapers/forest_road.png', name: 'Bosque'),
    WallpaperItem(path: 'assets/wallpapers/dark_forest_road.png', name: 'Bosque Oscuro'),
    WallpaperItem(path: 'assets/wallpapers/autumn_mountains.jpg', name: 'Otoño'),
    WallpaperItem(path: 'assets/wallpapers/mountain_lake.jpg', name: 'Lago Azul'),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
      name: 'Montaña Nevada',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',
      name: 'Aurora Boreal',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800&q=80',
      name: 'Ciudad Nocturna',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1557682250-33bd709cbe85?w=800&q=80',
      name: 'Abstracto',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=800&q=80',
      name: 'Océano',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800&q=80',
      name: 'Vía Láctea',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
      name: 'Playa',
    ),
    WallpaperItem(
      path: 'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=800&q=80',
      name: 'Entre Niebla',
    ),
  ];

  String? get backgroundImage => _backgroundImage;
  List<WallpaperItem> get wallpapers => _wallpapers;

  ImageProvider? get backgroundImageProvider {
    if (_backgroundImage == null) return null;
    if (_backgroundImage!.startsWith('assets/')) return AssetImage(_backgroundImage!);
    if (_backgroundImage!.startsWith('http')) return NetworkImage(_backgroundImage!);
    return FileImage(File(_backgroundImage!));
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
    final savedLang = prefs.getString('app_language');

    _backgroundImage = prefs.getString('backgroundImage');

    if (savedLang != null) {
      _appLocale = Locale(savedLang);
    }

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
