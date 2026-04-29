import 'dart:math';

class StringUtils {
  static String abbreviateAsignatura(String name) {
    if (name.isEmpty) return name;
    
    // 1. Si ya tiene paréntesis con sigla, extraerla: "Historia de España (HESP)" -> "HESP"
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(name);
    if (match != null) {
      return match.group(1)!;
    }
    
    // 2. Mapeo manual para casos comunes
    final mapping = {
      'APLICACIONES OFIMÁTICAS': 'APLOF',
      'MONTAJE Y MANTENIMIENTO DE EQUIPOS': 'MOMAE',
      'SISTEMAS OPERATIVOS MONOPUESTO': 'SOM',
      'ENTORNOS DE DESARROLLO': 'ENDES',
      'HISTORIA DE ESPAÑA': 'HESP',
      'SISTEMAS INFORMÁTICOS': 'SINF',
      'SISTEMAS OPERATIVOS': 'SISO',
      'SERVICIOS EN RED': 'SERRE',
      'SEGURIDAD INFORMÁTICA': 'SEGU',
      'DESARROLLO DE INTERFACES': 'DEINT',
      'ACCESO A DATOS': 'ACDAT',
      'PROGRAMACIÓN MULTIMEDIA Y DISPOSITIVOS MÓVILES': 'PMDMO',
      'PROGRAMACIÓN DE SERVICIOS Y PROCESOS': 'PSPRO',
      'SISTEMAS DE GESTIÓN EMPRESARIAL': 'SGEMP',
      'ITINERARIO PERSONAL PARA LA EMPLEABILIDAD I': 'IPE I',
      'ITINERARIO PERSONAL PARA LA EMPLEABILIDAD II': 'IPE II',
      'LENGUA CASTELLANA Y LITERATURA I': 'LCL I',
      'LENGUA CASTELLANA Y LITERATURA II': 'LCL II',
      'INGLÉS I': 'ING I',
      'INGLÉS II': 'ING II',
      'BIOLOGÍA Y GEOLOGÍA': 'BIGE',
      'BIOLOGÍA': 'BIO',
      'FÍSICA Y QUÍMICA': 'FYQ',
      'FÍSICA': 'FIS',
      'QUÍMICA': 'QUI',
      'MATEMÁTICAS I': 'MAT I',
      'MATEMÁTICAS II': 'MAT II',
      'FILOSOFÍA': 'FILO',
      'GEOGRAFÍA': 'GEOG',
      'HISTORIA DEL MUNDO COMTEMPORÁNEO': 'HMCO',
      'DIBUJO TÉCNICO I': 'DT I',
      'DIBUJO TÉCNICO II': 'DT II',
      'ECONOMÍA': 'ECON',
      'TECNOLOGÍA E INGENIERÍA I': 'TI I',
      'TECNOLOGÍA E INGENIERÍA II': 'TI II',
    };
    
    final upperName = name.trim().toUpperCase();
    if (mapping.containsKey(upperName)) {
      return mapping[upperName]!;
    }
    
    // 3. Fallback: Si contiene un guión bajo, podría ser una sigla (ej: SISTEMAS_GESTION -> SG)
    if (name.contains('_')) {
      return name.split('_').map((e) => e[0]).join('').toUpperCase();
    }
    
    // 4. Si es muy larga, recortar
    if (name.length > 12) {
      final words = name.split(' ').where((w) => w.length > 2).toList();
      if (words.length > 1) {
        return words.map((w) => w[0]).join('').toUpperCase();
      }
      return name.substring(0, min(name.length, 8)).toUpperCase();
    }
    
    return name;
  }
}
