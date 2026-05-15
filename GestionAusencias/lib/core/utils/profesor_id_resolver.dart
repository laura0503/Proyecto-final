import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<int?> resolverIdProfesorReal(SupabaseClient supabase, String emailNombre) async {
  final authUser = supabase.auth.currentUser;
  final googleEmail = authUser?.email ?? emailNombre;

  try {
    final byEmail = await supabase
        .from('profesores')
        .select('id_profesor, nombre')
        .eq('email', googleEmail)
        .not('nombre', 'ilike', '%@%')
        .maybeSingle();
    if (byEmail != null) {
      final id = byEmail['id_profesor'] as int?;
      debugPrint('[Resolver] Por email: $googleEmail → id=$id (${byEmail['nombre']})');
      return id;
    }
  } catch (_) {}

  final meta = authUser?.userMetadata ?? {};
  final candidatos = <String>{};
  for (final key in ['full_name', 'name']) {
    final v = meta[key]?.toString().trim();
    if (v != null && v.isNotEmpty) candidatos.add(v);
  }
  final given = meta['given_name']?.toString().trim() ?? '';
  final family = meta['family_name']?.toString().trim() ?? '';
  if (given.isNotEmpty && family.isNotEmpty) candidatos.add('$given $family');

  debugPrint('[Resolver] email=$googleEmail meta=$meta candidatos=$candidatos');

  if (candidatos.isNotEmpty) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâäã]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôöõ]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ñ', 'n');

    final allProfs = await supabase
        .from('profesores')
        .select('id_profesor, nombre')
        .not('nombre', 'ilike', '%@%');

    for (final nombre in candidatos) {
      final tokens = norm(nombre).split(RegExp(r'[\s,]+')).where((t) => t.length > 2).toList();
      if (tokens.length < 2) continue;
      for (final p in allProfs as List) {
        final nombreNorm = norm(p['nombre'] as String? ?? '');
        if (tokens.where((t) => nombreNorm.contains(t)).length >= 2) {
          final id = p['id_profesor'] as int?;
          debugPrint('[Resolver] Por tokens "$nombre" → id=$id (${p['nombre']})');
          return id;
        }
      }
    }
  }

  debugPrint('[Resolver] Sin coincidencia — ejecuta el SQL de vinculación en Supabase');
  return null;
}
