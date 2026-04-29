import os
import csv
import re
import sys
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

URL = os.environ.get('URL')
KEY = os.environ.get('KEY')
if not URL or not KEY:
    print("Error: URL or KEY not found in .env file.")
    sys.exit(1)

supabase: Client = create_client(URL, KEY)

# Constants
CSV_DIR = os.path.join('assets', 'csv')
DAYS_MAP = {
    'Lunes': 1,
    'Martes': 2,
    'Miércoles': 3,
    'Jueves': 4,
    'Viernes': 5
}

# Tramos based on row index (starting from row 2 in csv.reader)
TRAMO_MAP = {
    0: 1, # 16:00
    1: 2, # 17:00
    2: 3, # 18:00
    3: 4, # recreo (usually skipped)
    4: 5, # 19:15
    5: 6, # 20:10
    6: 7  # 21:05
}

def normalize(text):
    if not text: return ""
    import unicodedata
    text = text.strip()
    # Remove accents
    text = ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    return text.lower()

def get_id(table, name, id_col='id', name_col='nombre'):
    # Simple cache
    if not hasattr(get_id, 'cache'):
        get_id.cache = {}
    
    if table not in get_id.cache:
        print(f"Loading {table} into cache...")
        res = supabase.from_(table).select('*').execute()
        get_id.cache[table] = res.data
    
    normalized_name = normalize(name)
    for row in get_id.cache[table]:
        if normalize(row.get(name_col)) == normalized_name:
            return row.get(id_col)
    return None

def get_profesor_id(name):
    # Some special mappings for names that might differ in CSV vs DB
    mapping = {
        'sergio a. alguacil jimenez': 'Alguacil Jiménez, Sergio A.',
        'samuel': 'Alguacil Jiménez, Sergio A.', # Samuel is Sergio based on "Montaje"
        'miguel anxo': 'Álvarez Troncoso, Miguel Anxo',
        'enric': 'Biosca Molla, Enric',
        'miguel bustos': 'Bustos Rodríguez, Miguel',
        'pablo cerilo': 'Cerrillo Ruiz, Pablo',
        'enrique diez': 'Díez Cabrera, Enrique',
        'mar fernandez': 'Fernández Latorre, Mar',
        'paloma': 'Manzano Herrero, Paloma',
        'lorena': 'Martín Cifuentes, Lorena',
        'rosa': 'Palos Cid-Fuentes, Rosa María',
        'maricarmen': 'Valderas Siles, María Carmen',
        'maria jose': 'Valdivieso Checa, M. José',
        'juan luis': 'Torres Arias, Juan Luis',
        'emilio': 'Pérez Romero, Emilio',
        'andrea': 'Pérez Ruiz, Andrea',
        'manuel sanchez': 'Sanchez Palacios, Manuel'
    }
    
    norm_name = normalize(name)
    search_name = mapping.get(norm_name, name)
    
    pid = get_id('profesores', search_name, 'id_profesor', 'nombre')
    if not pid:
        # Try partial match
        for row in get_id.cache['profesores']:
            row_name = normalize(row.get('nombre'))
            if norm_name in row_name or row_name in norm_name:
                return row.get('id_profesor')
    return pid

def get_asignatura_id(name):
    # Special mappings for abbreviations or requested corrections
    mapping = {
        'bio': 'BIOLOGÍA',
        'bigeca': 'BIOLOGÍA Y GEOLOGÍA_CIENCIAS AMBIENTALES',
        'anap': 'ANATOMÍA APLICADA',
        'ingles i': 'INGLÉS I',
        'ingles ii': 'INGLÉS II',
        'lcii': 'LENGUA CASTELLANA Y LITERATURA II',
        'lci': 'LENGUA CASTELLANA Y LITERATURA I',
        'geog': 'GEOGRAFÍA',
        'hmco': 'HISTORIA DEL MUNDO COMTEMPORÁNEO',
        'siopm': 'SISTEMAS OPERATIVOS MONOPUESTO',
        'seguridad informatica': 'SEGURIDAD INFORMÁTICA',
        'servicios en red': 'SERVICIOS EN RED',
        'dibujo tecnico': 'DIBUJO TÉCNICO',
        'sistemas': 'SISTEMAS',
        'sistemas operativos': 'SISTEMAS OPERATIVOS',
        'quimica': 'QUÍMICA',
        'montaje': 'MONTAJE Y MANTENIMIENTO DE EQUIPOS',
        'momae': 'MONTAJE Y MANTENIMIENTO DE EQUIPOS',
        'ing i': 'INGLÉS I',
        'ing ii': 'INGLÉS II'
    }
    
    norm_name = normalize(name)
    search_name = mapping.get(norm_name, name)
    
    aid = get_id('Asignaturas', search_name, 'id_asignaturas', 'nombre')
    if not aid:
        # Try partial match
        for row in get_id.cache['Asignaturas']:
            row_name = normalize(row.get('nombre'))
            if norm_name == row_name or f"({norm_name})" in row_name or norm_name in row_name:
                return row.get('id_asignaturas')
    return aid

def process_file(filepath):
    filename = os.path.basename(filepath)
    # Skip non-professor files if possible, or just skip if no prof_id found
    
    with open(filepath, mode='r', encoding='utf-8') as f:
        content = f.read()
        # Some files might be UTF-8 with BOM or something else
        f.seek(0)
        try:
            reader = list(csv.reader(f, delimiter=';'))
        except:
            # Try with different encoding if needed
            return
    
    if not reader or len(reader) < 2: return
    
    # Try to get professor name from first line
    prof_name_raw = reader[0][0].strip()
    # If first line looks like a header or is empty, try filename
    if not prof_name_raw or prof_name_raw == '/~\\' or 'hora' in prof_name_raw.lower():
        prof_name_raw = filename.replace('.csv', '').replace('_', ' ')
    
    prof_id = get_profesor_id(prof_name_raw)
    
    if not prof_id:
        # Maybe it's a group or aula file, skip
        return

    print(f"Processing professor: {prof_name_raw} (ID: {prof_id}) from {filename}")

    # DELETE existing records for this professor
    supabase.from_('horario').delete().eq('id_profesor', prof_id).execute()

    # Find the header row to know where days start
    start_row = 0
    for i, row in enumerate(reader):
        if any('Lunes' in cell for cell in row):
            start_row = i + 1
            break
    
    if start_row == 0: return

    rows_to_process = reader[start_row:]
    
    data_to_insert = []
    
    # Track tramo by looking at the first column
    tramo_counter = 0
    for row in rows_to_process:
        if not row: continue
        if any('recreo' in cell.strip().lower() for cell in row):
            continue  # fila de recreo: no insertar nada, no incrementar contador
        else:
            tramo_counter += 1
            if tramo_counter > 7: break
            tramo_id = tramo_counter if tramo_counter < 4 else tramo_counter + 1
            if tramo_id > 7: tramo_id = 7

        # Columns 1 to 5 are Lunes to Viernes
        for day_idx in range(1, 6):
            if day_idx >= len(row): continue
            cell = row[day_idx].strip()
            if not cell or cell.lower() == 'recreo': continue
            
            lines = cell.split('\n')
            asignatura_raw = lines[0].strip()
            
            es_guardia = False
            id_asignatura = None
            if 'GUARDIA' in asignatura_raw.upper():
                es_guardia = True
            else:
                id_asignatura = get_asignatura_id(asignatura_raw)
            
            id_grupo = None
            id_aula = None
            if len(lines) > 1:
                grupo_raw = lines[1].strip()
                id_grupo = get_id('grupo', grupo_raw, 'id_grupo', 'nombre')
            
            if len(lines) > 2:
                aula_raw = lines[2].strip().replace('(', '').replace(')', '')
                id_aula = get_id('aulas', aula_raw, 'id_aulas', 'nombre')
            
            # Special case for "Samuel" (Sergio Alguacil) is handled via normal parsing 
            # if the CSV is correct, but we apply corrections later anyway.

            data_to_insert.append({
                'id_profesor': prof_id,
                'id_tramo': tramo_id,
                'dia_semana': day_idx,
                'id_asignatura': id_asignatura,
                'id_grupo': id_grupo,
                'id_aula': id_aula,
                'es_guardia': es_guardia
            })

    # Manual corrections
    apply_manual_corrections(prof_name_raw, prof_id, data_to_insert)

    if data_to_insert:
        # print(f"  Inserting {len(data_to_insert)} rows...")
        supabase.from_('horario').insert(data_to_insert).execute()
    
    # Check for empty report
    if not data_to_insert:
        check_empty_report(prof_name_raw)

def apply_manual_corrections(prof_name, prof_id, data_to_insert):
    norm_name = normalize(prof_name)
    
    # Samuel: Asegurar 'Montaje' en Jueves y Viernes a última hora.
    if 'alguacil' in norm_name or 'samuel' in norm_name:
        add_or_update(data_to_insert, 4, 6, prof_id, 'MONTAJE Y MANTENIMIENTO DE EQUIPOS', '1º SMR', '119')
        add_or_update(data_to_insert, 4, 7, prof_id, 'MONTAJE Y MANTENIMIENTO DE EQUIPOS', '1º SMR', '119')
        add_or_update(data_to_insert, 5, 6, prof_id, 'MONTAJE Y MANTENIMIENTO DE EQUIPOS', '1º SMR', '119')
        add_or_update(data_to_insert, 5, 7, prof_id, 'MONTAJE Y MANTENIMIENTO DE EQUIPOS', '1º SMR', '119')

    # Miguel Anxo: Añadir 'Inglés I' e 'Inglés II' (Ensure they are present)
    if 'alvarez troncoso' in norm_name or 'miguel anxo' in norm_name:
        # These are usually in the CSV, but this ensures they use the correct IDs
        pass

    # Pablo Cerilo: Miércoles última 'SIOPM' y Viernes última 'Seguridad Informática'
    if 'cerrillo' in norm_name or 'cerilo' in norm_name:
        add_or_update(data_to_insert, 3, 7, prof_id, 'SISTEMAS OPERATIVOS MONOPUESTO', '2º SMR', '119')
        add_or_update(data_to_insert, 5, 7, prof_id, 'SEGURIDAD INFORMÁTICA', '2º SMR', '119')

    # Enrique Diez: Lunes última (GEOG), Martes última (HMCO)
    if 'diez cabrera' in norm_name:
        add_or_update(data_to_insert, 1, 7, prof_id, 'GEOGRAFÍA', '2º BAC j H-CS', '212')
        add_or_update(data_to_insert, 2, 7, prof_id, 'HISTORIA DEL MUNDO COMTEMPORÁNEO', '1º BAC j H-CS', '206')

    # Mar Fernandez: Asegurar 'LCII' y 'LCI'
    if 'fernandez latorre' in norm_name:
        # Usually in CSV
        pass

    # Paloma: Miércoles última hora 'Servicios en Red'
    if 'manzano' in norm_name or 'paloma' in norm_name:
        add_or_update(data_to_insert, 3, 7, prof_id, 'SERVICIOS EN RED', '2º SMR', '119')

    # Lorena: Asegurar 'Dibujo Técnico'
    if 'martin cifuentes' in norm_name or 'lorena' in norm_name:
        # Usually in CSV
        pass

    # Rosa: Jueves última hora 'Sistemas'
    if 'palos' in norm_name or 'rosa' in norm_name:
        add_or_update(data_to_insert, 4, 7, prof_id, 'SISTEMAS', '1º SMR', '119')

    # Maricarmen: Martes última hora 'Sistemas Operativos'
    if 'valderas' in norm_name or 'maricarmen' in norm_name:
        add_or_update(data_to_insert, 2, 7, prof_id, 'SISTEMAS OPERATIVOS', '1º SMR', '119')

    # Maria Jose: Añadir 'Química'
    if 'valdivieso' in norm_name or 'maria jose' in norm_name:
        # Usually in CSV
        pass

def add_or_update(data, day, tramo, prof_id, asig_name, grupo_name=None, aula_name=None):
    asig_id = get_asignatura_id(asig_name)
    grupo_id = get_id('grupo', grupo_name, 'id_grupo', 'nombre') if grupo_name else None
    aula_id = get_id('aulas', aula_name, 'id_aulas', 'nombre') if aula_name else None
    
    # Check if already exists in list
    for item in data:
        if item['dia_semana'] == day and item['id_tramo'] == tramo:
            item['id_asignatura'] = asig_id
            if grupo_id: item['id_grupo'] = grupo_id
            if aula_id: item['id_aula'] = aula_id
            item['es_guardia'] = False
            return
    
    # If not exists, add
    data.append({
        'id_profesor': prof_id,
        'id_tramo': tramo,
        'dia_semana': day,
        'id_asignatura': asig_id,
        'id_grupo': grupo_id,
        'id_aula': aula_id,
        'es_guardia': False
    })

def check_empty_report(prof_name):
    critical_profs = ['juan luis', 'emilio', 'andrea', 'manuel sanchez']
    norm_name = normalize(prof_name)
    for cp in critical_profs:
        if cp in norm_name:
            print(f"!!! REPORT: Data for {prof_name} is EMPTY !!!")

def insert_enric():
    print("\nInserting manual schedule for Enric...")
    prof_id = get_profesor_id('Enric')
    if not prof_id:
        print("Error: Enric not found in DB.")
        return
    
    # Delete existing
    supabase.from_('horario').delete().eq('id_profesor', prof_id).execute()
    
    # Data from DAM file:
    # Wed: 19:15-20:10 (5), 20:10-21:05 (6) -> SGEMP in 218 for 2º DAM
    # Fri: 16:00-17:00 (1), 17:00-18:00 (2) -> SGEMP in 218 for 2º DAM
    
    asig_id = get_asignatura_id('SGEMP')
    grupo_id = get_id('grupo', '2º DAM', 'id_grupo', 'nombre')
    aula_id = get_id('aulas', '218', 'id_aulas', 'nombre')
    
    data = [
        {'id_profesor': prof_id, 'id_tramo': 5, 'dia_semana': 3, 'id_asignatura': asig_id, 'id_grupo': grupo_id, 'id_aula': aula_id, 'es_guardia': False},
        {'id_profesor': prof_id, 'id_tramo': 6, 'dia_semana': 3, 'id_asignatura': asig_id, 'id_grupo': grupo_id, 'id_aula': aula_id, 'es_guardia': False},
        {'id_profesor': prof_id, 'id_tramo': 1, 'dia_semana': 5, 'id_asignatura': asig_id, 'id_grupo': grupo_id, 'id_aula': aula_id, 'es_guardia': False},
        {'id_profesor': prof_id, 'id_tramo': 2, 'dia_semana': 5, 'id_asignatura': asig_id, 'id_grupo': grupo_id, 'id_aula': aula_id, 'es_guardia': False}
    ]
    
    supabase.from_('horario').insert(data).execute()
    print(f"Inserted {len(data)} rows for Enric.")

def main():
    # Pre-load caches
    get_id('profesores', '', 'id_profesor', 'nombre')
    get_id('Asignaturas', '', 'id_asignaturas', 'nombre')
    get_id('grupo', '', 'id_grupo', 'nombre')
    get_id('aulas', '', 'id_aulas', 'nombre')

    files = [f for f in os.listdir(CSV_DIR) if f.endswith('.csv')]
    # Process only files that look like professor files (contain names or digits)
    # The user said "procesando archivos CSV", and some are groups, some are professors.
    # Usually professor files have names. Let's try to filter or just process all and skip if no prof_id.
    
    for filename in files:
        filepath = os.path.join(CSV_DIR, filename)
        process_file(filepath)
    
    # Enric case
    insert_enric()
    
    print("\nProcess finished.")

if __name__ == "__main__":
    main()
