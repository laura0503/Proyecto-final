enum CsvContext { profesor, aula, grupo, unknown }

const Map<String, List<String>> kDeptoKeywords = {
  'Inglés': ['INGLÉS', 'ING I', 'ING II', 'ACI I', 'ACI II', 'ENGLISH'],
  'Lengua': ['LENGUA', 'LCL I', 'LCL II', 'ACL I', 'ACL II', 'LITERATURA', 'LCL', 'DACE'],
  'Matemáticas': ['MATEMÁTICAS', 'MAT I', 'MAT II', 'MAT', 'MTM'],
  'Filosofía': ['FILOSOFÍA', 'FILO', 'HFIL', 'PSICO'],
  'Biología': ['BIOLOGÍA', 'GEOLOGÍA', 'ANAP', 'BIGECA', 'BIGECB', 'CIENCIAS'],
  'Física y Química': ['FÍSICA', 'QUÍMICA', 'FYQ', 'QUI'],
  'Geografía e Historia': ['GEOGRAFÍA', 'HISTORIA', 'GEOG', 'HMCO', 'HES', 'GH'],
  'Informática': [
    'INFORMÁTICA', 'SMR', 'DAM', 'APLOF', 'MOMAE', 'DASPGM',
    'SASP', 'TICO', 'REDES', 'PROGRAMACIÓN', 'OFIMÁTICAS', 'INF'
  ],
  'Dibujo': ['DIBUJO', 'DBT', 'ALR', 'PLÁSTICA', 'DIB'],
  'ESPA': ['ESPA', 'ÁMBITO', 'ASO I', 'ASO II', 'ACT I', 'ACT II'],
  'Orientación': ['ORIENTACIÓN', 'FOL', 'EIE', 'FORMACIÓN'],
  'Religión': ['RELIGIÓN', 'REL'],
  'Educación Física': ['EDUCACIÓN FÍSICA', 'EF', 'EDF'],
  'Latín y Griego': ['LATÍN', 'GRIEGO', 'LAT', 'GRI'],
  'Economía': ['ECONOMÍA', 'ECO'],
  'Guardia': ['GUARDIA', 'GDIA', 'GDA', 'VIGILANCIA'],
};
