import os, csv, re, glob, unicodedata, io
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
supabase = create_client(os.environ.get('URL'), os.environ.get('KEY'))

profs_db  = supabase.table('profesores').select('id_profesor, nombre').execute().data
grupos_db = supabase.table('grupo').select('id_grupo, nombre').execute().data
aulas_db  = supabase.table('aulas').select('id_aulas, nombre').execute().data
tramos_db = supabase.table('horario_tramo').select('id_horario, horario_inicio').execute().data

def norm(s):
    s = unicodedata.normalize('NFC', str(s))
    for a, b in [('á','a'),('é','e'),('í','i'),('ó','o'),('ú','u'),('ñ','n'),
                 ('à','a'),('è','e'),('ì','i'),('ò','o'),('ù','u'),
                 ('Á','a'),('É','e'),('Í','i'),('Ó','o'),('Ú','u'),('Ñ','n')]:
        s = s.replace(a, b)
    return s.lower().replace(',','').replace('.','').replace(' ','').replace('﻿','').strip()

def find_id(items, id_col, name_col, name):
    if not name: return None
    n = norm(name)
    for x in items:
        if norm(x[name_col]) == n:
            return x[id_col]
    return None

def find_tramo(hora):
    hora = hora.strip()
    if len(hora) == 5: hora = hora + ':00'
    for t in tramos_db:
        ti = (t['horario_inicio'] or '')[:8]
        if ti == hora: return t['id_horario']
    return None

def read_csv(path):
    with open(path, 'rb') as f:
        raw = f.read()
    # Normalizar saltos de linea: \r\r\n -> \n, \r\n -> \n, \r -> \n
    content = raw.decode('utf-8', errors='replace')
    content = content.replace('\r\r\n', '\n').replace('\r\n', '\n').replace('\r', '\n')
    rows = list(csv.reader(io.StringIO(content), delimiter=';'))
    ctx_name = rows[0][0].strip().strip("'").strip('"') if rows else ''
    return ctx_name, rows

def parse_lines(cell):
    """Devuelve lineas limpias de una celda."""
    return [l.strip().strip("'") for l in cell.split('\n') if l.strip().strip("'")]

updates = []

# ── CSVs de GRUPO ────────────────────────────────────────────────────────────
grupo_patterns = [
    'assets/csv/1__BAC*.csv', 'assets/csv/2__BAC*.csv',
    'assets/csv/1__DAM*.csv', 'assets/csv/2__DAM*.csv',
    'assets/csv/1__SMR*.csv', 'assets/csv/2__SMR*.csv',
    'assets/csv/ESPA_I_*.csv', 'assets/csv/ESPA_II_1*.csv',
]
grupo_csvs = []
for pat in grupo_patterns:
    grupo_csvs.extend(glob.glob(pat))
print(f'CSVs de grupo: {len(grupo_csvs)}')

for path in grupo_csvs:
    ctx_name, rows = read_csv(path)
    grupo_id = find_id(grupos_db, 'id_grupo', 'nombre', ctx_name)
    if not grupo_id:
        print(f'  SKIP grupo: "{ctx_name}"')
        continue

    count = 0
    for row in rows:
        if not row or not row[0]: continue
        lines0 = parse_lines(row[0])
        if not lines0: continue
        hora_m = re.match(r'(\d{1,2}:\d{2})', lines0[0])
        if not hora_m: continue
        tramo_id = find_tramo(hora_m.group(1))
        if not tramo_id: continue

        for dia_idx in range(1, 6):
            if dia_idx >= len(row): continue
            lines = parse_lines(row[dia_idx])
            if not lines: continue
            asignatura = lines[0]
            if re.match(r'\d{2}:\d{2}', asignatura) or asignatura.lower() in ('recreo','guardia'): continue

            # Formato grupo CSV: asignatura / profesor / (aula)
            prof_nombre = None
            aula_nombre = None
            for l in lines[1:]:
                aula_m = re.fullmatch(r'\((\d+)\)', l)
                if aula_m:
                    aula_nombre = aula_m.group(1)
                elif ',' in l:
                    prof_nombre = l

            if not prof_nombre: continue
            prof_id = find_id(profs_db, 'id_profesor', 'nombre', prof_nombre)
            if not prof_id: continue
            aula_id = find_id(aulas_db, 'id_aulas', 'nombre', aula_nombre) if aula_nombre else None

            updates.append({'id_profesor': prof_id, 'id_tramo': tramo_id, 'dia_semana': dia_idx,
                            'id_grupo': grupo_id, 'id_aula': aula_id})
            count += 1
    print(f'  {ctx_name}: {count} registros')

# ── CSVs de AULA ─────────────────────────────────────────────────────────────
aula_csvs = [f for f in glob.glob('assets/csv/*.csv') if os.path.basename(f)[0].isdigit()]
print(f'\nCSVs de aula: {len(aula_csvs)}')

for path in aula_csvs:
    ctx_name, rows = read_csv(path)
    if ctx_name.lower() == 'id' or not ctx_name[0].isdigit(): continue
    aula_id = find_id(aulas_db, 'id_aulas', 'nombre', ctx_name)
    if not aula_id:
        print(f'  SKIP aula: "{ctx_name}"')
        continue

    count = 0
    for row in rows:
        if not row or not row[0]: continue
        lines0 = parse_lines(row[0])
        if not lines0: continue
        hora_m = re.match(r'(\d{1,2}:\d{2})', lines0[0])
        if not hora_m: continue
        tramo_id = find_tramo(hora_m.group(1))
        if not tramo_id: continue

        for dia_idx in range(1, 6):
            if dia_idx >= len(row): continue
            lines = parse_lines(row[dia_idx])
            if not lines or len(lines) < 2: continue
            asignatura = lines[0]
            if re.match(r'\d{2}:\d{2}', asignatura) or asignatura.lower() in ('recreo','guardia'): continue

            # Formato aula CSV: asignatura / profesor / grupo
            prof_nombre = None
            grupo_nombre = None
            for l in lines[1:]:
                if ',' in l and not re.search(r'\dº|\d\s*o\s', l, re.I):
                    prof_nombre = l
                elif re.search(r'\d\s*[oº°]\s*(BAC|DAM|SMR)|ESPA', l, re.IGNORECASE):
                    grupo_nombre = l

            if not prof_nombre: continue
            prof_id = find_id(profs_db, 'id_profesor', 'nombre', prof_nombre)
            if not prof_id: continue
            grupo_id = find_id(grupos_db, 'id_grupo', 'nombre', grupo_nombre) if grupo_nombre else None

            updates.append({'id_profesor': prof_id, 'id_tramo': tramo_id, 'dia_semana': dia_idx,
                            'id_grupo': grupo_id, 'id_aula': aula_id})
            count += 1
    print(f'  Aula {ctx_name}: {count} registros')

# ── CSVs de PROFESOR ──────────────────────────────────────────────────────────
# Formato celda profesor: ASIGNATURA + GRUPO + (AULA) [packed o multilinea]
prof_csvs = [f for f in glob.glob('assets/csv/*.csv')
             if not os.path.basename(f)[0].isdigit()
             and os.path.basename(f) not in [os.path.basename(x) for x in grupo_csvs]]
print(f'\nCSVs de profesor: {len(prof_csvs)}')

for path in prof_csvs:
    ctx_name, rows = read_csv(path)
    if not ctx_name or ctx_name.lower() in ('id', '') : continue
    # El nombre del profesor tiene coma => formato "Apellidos, Nombre"
    if ',' not in ctx_name: continue
    prof_id = find_id(profs_db, 'id_profesor', 'nombre', ctx_name)
    if not prof_id:
        continue

    count = 0
    for row in rows:
        if not row or not row[0]: continue
        lines0 = parse_lines(row[0])
        if not lines0: continue
        hora_m = re.match(r'(\d{1,2}:\d{2})', lines0[0])
        if not hora_m: continue
        tramo_id = find_tramo(hora_m.group(1))
        if not tramo_id: continue

        for dia_idx in range(1, 6):
            if dia_idx >= len(row): continue
            lines = parse_lines(row[dia_idx])
            if not lines: continue
            asignatura = lines[0]
            if re.match(r'\d{2}:\d{2}', asignatura) or asignatura.lower() in ('recreo','guardia'): continue

            # En CSV de profesor: asignatura / grupo / (aula)
            # Puede ser multilínea O todo comprimido en la primera línea
            grupo_nombre = None
            aula_nombre  = None

            # Caso comprimido en línea 0: "APLOF 1º SMR(119)" o "GUARDIA GUARDIA"
            packed0 = re.search(r'(\d\s*[oº°]\s*(?:BAC\s*[ij]?\s*[\w\-]*|DAM|SMR|ESPA\s*\w*))\s*(?:\((\d+)\))?', lines[0], re.I)
            if packed0:
                grupo_nombre = packed0.group(1).strip()
                aula_nombre  = packed0.group(2)

            for l in lines[1:]:
                aula_m = re.fullmatch(r'\((\d+)\)', l)
                if aula_m:
                    aula_nombre = aula_m.group(1)
                elif re.search(r'\d\s*[oº°]\s*(BAC|DAM|SMR)|ESPA', l, re.IGNORECASE):
                    grupo_nombre = l
                packed = re.search(r'(\d\s*[oº°]\s*(?:BAC\s*[ij]?\s*[\w\-]*|DAM|SMR|ESPA\s*\w*))\s*\((\d+)\)', l, re.I)
                if packed:
                    grupo_nombre = packed.group(1).strip()
                    aula_nombre  = packed.group(2)

            grupo_id = find_id(grupos_db, 'id_grupo', 'nombre', grupo_nombre) if grupo_nombre else None
            aula_id  = find_id(aulas_db, 'id_aulas', 'nombre', aula_nombre) if aula_nombre else None
            if not grupo_id and not aula_id: continue

            updates.append({'id_profesor': prof_id, 'id_tramo': tramo_id, 'dia_semana': dia_idx,
                            'id_grupo': grupo_id, 'id_aula': aula_id})
            count += 1

print(f'\nTotal registros: {len(updates)}')

# Consolidar por (prof, tramo, dia)
key_map = {}
for u in updates:
    k = (u['id_profesor'], u['id_tramo'], u['dia_semana'])
    ex = key_map.get(k)
    if not ex:
        key_map[k] = u
    else:
        ns = (1 if u['id_grupo'] else 0) + (1 if u['id_aula'] else 0)
        os_ = (1 if ex['id_grupo'] else 0) + (1 if ex['id_aula'] else 0)
        if ns > os_: key_map[k] = u

print(f'Claves unicas: {len(key_map)}')

actualizados = 0
for (prof_id, tramo_id, dia), u in key_map.items():
    if not u['id_grupo'] and not u['id_aula']: continue
    upd = {}
    if u['id_grupo']: upd['id_grupo'] = u['id_grupo']
    if u['id_aula']:  upd['id_aula']  = u['id_aula']
    try:
        r = supabase.table('horario').update(upd) \
            .eq('id_profesor', prof_id).eq('id_tramo', tramo_id).eq('dia_semana', dia).execute()
        actualizados += len(r.data)
    except Exception as e:
        print(f'  ERROR: {e}')

print(f'Filas actualizadas: {actualizados}')

h = supabase.table('horario').select('id_grupo, id_aula').execute().data
sin_g = sum(1 for x in h if x['id_grupo'] is None)
sin_a = sum(1 for x in h if x['id_aula'] is None)
print(f'\n=== RESULTADO FINAL ===')
print(f'Total: {len(h)}  |  Sin grupo: {sin_g} (antes 343)  |  Sin aula: {sin_a} (antes 351)')
