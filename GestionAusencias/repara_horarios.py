import os
import csv
import re
import sys
import unicodedata
from supabase import create_client, Client
from dotenv import load_dotenv

# --- CONFIGURACIÓN DE ENTORNO ---
load_dotenv()
URL = os.environ.get('URL')
KEY = os.environ.get('KEY')

if not URL or not KEY:
    print("Error: URL o KEY no encontradas en el archivo .env")
    sys.exit(1)

supabase: Client = create_client(URL, KEY)

# Directorio de los archivos CSV (con fallback)
CSV_DIR = 'horarios_csv'
if not os.path.exists(CSV_DIR):
    CSV_DIR = os.path.join('assets', 'csv')

# --- UTILIDADES DE DBA ---

def normalizar(texto):
    if not texto: return ""
    texto = str(texto).strip()
    texto = ''.join(c for c in unicodedata.normalize('NFD', texto) if unicodedata.category(c) != 'Mn')
    return texto.lower()

def obtener_ids_referencia():
    tablas = {
        'profesores': ('id_profesor', 'nombre'),
        'Asignaturas': ('id_asignaturas', 'nombre'),
        'grupo': ('id_grupo', 'nombre'),
        'aulas': ('id_aulas', 'nombre'),
        'horario_tramo': ('id_horario', 'horario_inicio')
    }
    cache = {}
    for tabla, (id_col, name_col) in tablas.items():
        print(f"Caché de DBA: Cargando tabla {tabla}...")
        res = supabase.table(tabla).select('*').execute()
        cache[tabla] = res.data
    return cache

CACHE = obtener_ids_referencia()

def buscar_id(tabla, valor, columna_busqueda='nombre'):
    if not valor: return None
    val_norm = normalizar(valor)
    id_col = {
        'profesores': 'id_profesor',
        'Asignaturas': 'id_asignaturas',
        'grupo': 'id_grupo',
        'aulas': 'id_aulas',
        'horario_tramo': 'id_horario'
    }.get(tabla)

    for row in CACHE.get(tabla, []):
        if normalizar(row.get(columna_busqueda)) == val_norm:
            return row.get(id_col)
    
    # Búsqueda de aula numérica (ej: '119' -> 'Aula 119')
    if tabla == 'aulas':
        val_digit = re.sub(r'\D', '', valor)
        if val_digit:
            for row in CACHE.get(tabla, []):
                if val_digit in row.get(columna_busqueda):
                    return row.get(id_col)

    if tabla in ['Asignaturas', 'profesores', 'grupo']:
        for row in CACHE.get(tabla, []):
            db_val = normalizar(row.get(columna_busqueda))
            if (len(val_norm) > 3 and val_norm in db_val) or (len(db_val) > 3 and db_val in val_norm):
                return row.get(id_col)
    
    return None

def detectar_tipo_y_id(lineas, filename):
    header = lineas[0].split(';')[0].strip().replace('"', '')
    
    # Profesor?
    pid = buscar_id('profesores', header)
    if pid: return 'PROFESOR', pid, header
    
    # Grupo?
    gid = buscar_id('grupo', header)
    if gid: return 'GRUPO', gid, header
    
    # Aula?
    aid = buscar_id('aulas', header)
    if aid: return 'AULA', aid, header
    
    # Fallback al filename como profesor
    name_from_file = filename.replace('.csv', '').replace('_', ' ')
    pid = buscar_id('profesores', name_from_file)
    if pid: return 'PROFESOR', pid, name_from_file
    
    return None, None, None

# --- LÓGICA DE NEGOCIO ---

def aplicar_parches_criticos(all_records):
    """Aplica parches a la lista global de registros acumulados."""
    # Mapeo de asignaturas para parches
    ASIG_MAP = {
        'montaje': 'MONTAJE Y MANTENIMIENTO DE EQUIPOS',
        'siopm': 'SISTEMAS OPERATIVOS MONOPUESTO',
        'seguridad informatica': 'SEGURIDAD INFORMÁTICA',
        'geog': 'GEOGRAFÍA',
        'hmco': 'HISTORIA DEL MUNDO COMTEMPORÁNEO',
        'servicios en red': 'SERVICIOS EN RED',
        'sistemas': 'SISTEMAS',
        'sistemas operativos': 'SISTEMAS OPERATIVOS'
    }

    def forzar_o_añadir(prof_search, dia, tramo, asig_nom, grupo_nom=None, aula_nom=None):
        p_id = buscar_id('profesores', prof_search)
        if not p_id: return
        
        id_asig = buscar_id('Asignaturas', ASIG_MAP.get(asig_nom.lower(), asig_nom))
        id_grupo = buscar_id('grupo', grupo_nom) if grupo_nom else None
        id_aula = buscar_id('aulas', aula_nom) if aula_nom else None
        
        encontrado = False
        for r in all_records:
            if r['id_profesor'] == p_id and r['dia_semana'] == dia and r['id_tramo'] == tramo:
                r['id_asignatura'] = id_asig
                if id_grupo: r['id_grupo'] = id_grupo
                if id_aula: r['id_aula'] = id_aula
                r['es_guardia'] = False
                encontrado = True
                break
        
        if not encontrado:
            all_records.append({
                'id_profesor': p_id, 'id_tramo': tramo, 'dia_semana': dia,
                'id_asignatura': id_asig, 'id_grupo': id_grupo, 'id_aula': id_aula,
                'es_guardia': False
            })

    # Samuel (Sergio Alguacil)
    forzar_o_añadir('Samuel', 4, 7, 'Montaje', '1º SMR', '119')
    forzar_o_añadir('Samuel', 5, 7, 'Montaje', '1º SMR', '119')

    # Pablo Cerilo
    forzar_o_añadir('Pablo Cerilo', 3, 7, 'SIOPM', '2º SMR', '119')
    forzar_o_añadir('Pablo Cerilo', 5, 7, 'Seguridad Informática', '2º SMR', '119')

    # Enrique Diez
    forzar_o_añadir('Enrique Diez', 1, 7, 'GEOG', '2º BAC j H-CS', '212')
    forzar_o_añadir('Enrique Diez', 2, 7, 'HMCO', '1º BAC j H-CS', '206')

    # Paloma
    forzar_o_añadir('Paloma', 3, 7, 'Servicios en Red', '2º SMR', '119')

    # Rosa y Maricarmen
    forzar_o_añadir('Rosa', 4, 7, 'Sistemas', '1º SMR', '119')
    forzar_o_añadir('Maricarmen', 2, 7, 'Sistemas Operativos', '1º SMR', '119')

    # Enric (Manual)
    id_asig_sgemp = buscar_id('Asignaturas', 'SGEMP')
    id_grupo_dam = buscar_id('grupo', '2º DAM')
    id_aula_218 = buscar_id('aulas', '218')
    p_id_enric = buscar_id('profesores', 'Enric')
    if p_id_enric:
        tramos_enric = [(3, 5), (3, 6), (5, 1), (5, 2)]
        for dia, tramo in tramos_enric:
            forzar_o_añadir('Enric', dia, tramo, 'SGEMP', '2º DAM', '218')

def procesar_archivo(filepath, all_records):
    filename = os.path.basename(filepath)
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lineas = f.readlines()
    if not lineas: return

    tipo, header_id, header_name = detectar_tipo_y_id(lineas, filename)
    if not tipo: return

    print(f"DBA: Procesando {tipo}: {header_name} ({filename})")

    start_idx = 0
    for i, l in enumerate(lineas):
        if 'Lunes' in l:
            start_idx = i + 1
            break
    if start_idx == 0: return

    tramo_count = 0
    for l in lineas[start_idx:]:
        parts = l.strip().split(';')
        if not parts: continue
        time_part = parts[0].strip().lower()
        if 'recreo' in time_part: continue
        
        tramo_count += 1
        if tramo_count > 6: tramo_id = 7
        elif tramo_count <= 3: tramo_id = tramo_count
        else: tramo_id = tramo_count + 1
        if tramo_id > 7: break

        for dia_idx in range(1, 6):
            if dia_idx >= len(parts): continue
            celda = parts[dia_idx].strip().replace('"', '')
            if not celda or celda.lower() in ['nan', 'recreo', 'libre']: continue

            celda_parts = [p.strip() for p in re.split(r'\\n|\n', celda) if p.strip()]
            if not celda_parts: continue

            asig_txt = celda_parts[0]
            es_guardia = "GUARDIA" in asig_txt.upper()
            
            p_id, g_id, a_id = None, None, None
            asig_id = None if es_guardia else buscar_id('Asignaturas', asig_txt)

            if tipo == 'PROFESOR':
                p_id = header_id
                g_txt = celda_parts[1] if len(celda_parts) > 1 else None
                a_txt = celda_parts[2] if len(celda_parts) > 2 else None
                g_id = buscar_id('grupo', g_txt)
                a_id = buscar_id('aulas', re.sub(r'[\(\)]', '', a_txt)) if a_txt else None
            elif tipo == 'GRUPO':
                g_id = header_id
                p_txt = celda_parts[1] if len(celda_parts) > 1 else None
                a_txt = celda_parts[2] if len(celda_parts) > 2 else None
                p_id = buscar_id('profesores', p_txt)
                a_id = buscar_id('aulas', re.sub(r'[\(\)]', '', a_txt)) if a_txt else None
            elif tipo == 'AULA':
                a_id = header_id
                p_txt = celda_parts[1] if len(celda_parts) > 1 else None
                g_txt = celda_parts[2] if len(celda_parts) > 2 else None
                p_id = buscar_id('profesores', p_txt)
                g_id = buscar_id('grupo', g_txt)

            if p_id:
                all_records.append({
                    'id_profesor': p_id, 'id_tramo': tramo_id, 'dia_semana': dia_idx,
                    'id_asignatura': asig_id, 'id_grupo': g_id, 'id_aula': a_id,
                    'es_guardia': es_guardia
                })

def main():
    print("--- SCRIPT DE REPARACIÓN UNIVERSAL (DBA EXPERT V2) ---")
    all_records = []
    
    archivos = [os.path.join(CSV_DIR, f) for f in os.listdir(CSV_DIR) if f.endswith('.csv')]
    for f in archivos:
        try:
            procesar_archivo(f, all_records)
        except Exception as e:
            print(f"Error procesando {f}: {e}")

    # Aplicar parches y manuales
    aplicar_parches_criticos(all_records)

    # Agrupar por profesor para limpieza selectiva
    records_by_prof = {}
    for r in all_records:
        pid = r['id_profesor']
        if pid not in records_by_prof: records_by_prof[pid] = []
        # Evitar duplicados exactos
        if r not in records_by_prof[pid]:
            records_by_prof[pid].append(r)

    print(f"\nDBA: Total de profesores con datos encontrados: {len(records_by_prof)}")
    
    for pid, regs in records_by_prof.items():
        try:
            # Solo borramos si tenemos algo que insertar para ese profesor
            supabase.table("horario").delete().eq("id_profesor", pid).execute()
            # Dividir en chunks para evitar límites de Supabase si hay muchos registros
            for i in range(0, len(regs), 50):
                supabase.table("horario").insert(regs[i:i+50]).execute()
            print(f"DBA: OK - Profesor ID {pid} actualizado ({len(regs)} registros)")
        except Exception as e:
            print(f"Error actualizando profesor {pid}: {e}")

    print("\n--- OPERACIÓN DE DBA FINALIZADA CON ÉXITO ---")

if __name__ == "__main__":
    main()
