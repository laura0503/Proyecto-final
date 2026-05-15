import '../../domain/entities/profesor.dart';

String _normName(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[áàâä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòôö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll('ñ', 'n');

/// Returns the best matching [Profesor] for a Google-authenticated user,
/// or null if no match is found (caller should create a temporary profile).
Profesor? matchProfesorByGoogle(
  List<Profesor> profesores,
  String googleEmail,
  String? googleName,
) {
  final googleTokens = googleName != null
      ? _normName(googleName)
          .split(RegExp(r'[\s,]+'))
          .where((t) => t.length > 3)
          .toList()
      : <String>[];

  Profesor? profReal;
  if (googleTokens.length >= 2) {
    for (final p in profesores) {
      if (p.nombre.contains('@')) continue;
      final nombreNorm = _normName(p.nombre);
      final hits = googleTokens.where((t) => nombreNorm.contains(t)).length;
      if (hits >= 2) {
        profReal = p;
        break;
      }
    }
  }

  if (profReal != null) return profReal;

  return profesores.cast<Profesor?>().firstWhere(
    (p) {
      final nombreProfe = p!.nombre.toLowerCase().trim();
      if (nombreProfe == googleEmail) return true;
      if (googleName != null && nombreProfe == googleName.toLowerCase().trim()) return true;
      if (googleEmail.split('@').first == nombreProfe.split('@').first) return true;
      return false;
    },
    orElse: () => null,
  );
}
