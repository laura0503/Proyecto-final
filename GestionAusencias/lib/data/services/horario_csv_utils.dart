class HorarioCsvUtils {
  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  static bool contieneKeyword(String texto, List<String> keywords) {
    final t = _norm(texto);
    return keywords.any((kw) => t.contains(_norm(kw)));
  }

  static String sanitizar(String text) {
    if (text == '..' || text == '.' || text == '...') return '';
    String s = text.trim();
    if (s.startsWith('"') && s.endsWith('"')) s = s.substring(1, s.length - 1);
    final idx = s.indexOf(';');
    if (idx != -1) s = s.substring(0, idx).trim();
    s = s.replaceFirst(RegExp(r' Lectivas$'), '');
    s = s.replaceAll(RegExp(r'^\d+;'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static bool nombresCoinciden(String n1, String n2) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return norm(n1) == norm(n2);
  }

  static bool esBasura(String s) {
    if (s.isEmpty || s == '..' || s == '.') return true;
    if (RegExp(r'^\d{2}:\d{2}').hasMatch(s)) return true;
    final lower = s.toLowerCase();
    return lower == 'recreo' || lower.contains('lectivas');
  }

  static bool esNombreLargo(String s) =>
      s.length > 15 && s.contains(' ') && !RegExp(r'^\d').hasMatch(s);

  static bool esCadenaValida(String name) {
    final s = sanitizar(name);
    if (esBasura(s)) return false;
    if (s.length < 2 && !RegExp(r'^\d+$').hasMatch(s)) return false;
    return true;
  }
}
