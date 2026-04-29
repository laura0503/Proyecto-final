import os
import glob
import pandas as pd
from supabase import create_client
import io
import re
import unicodedata
from dotenv import load_dotenv

# --- CONFIGURACIÓN ---
load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def normalize_text(text):
    if not text:
        return ""
    text = str(text).strip().upper()
    # Reemplazar el carácter de reemplazo  por algo neutro o intentar corregirlo
    text = text.replace('', ' ')
    # Eliminar acentos
    text = "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )
    # Dejar solo letras y números
    text = re.sub(r'[^A-Z0-9]', '', text)
    return text

def get_lookup_maps():
    print("Cargando mapas de referencia desde la DB...")
    
    # Profesores: guardamos tanto el original como el normalizado
    prof_res = supabase.table("profesores").select("id_profesor, nombre").execute()
    prof_map = {}
    for p in prof_res.data:
        norm = normalize_text(p['nombre'])
        if norm:
            prof_map[norm] = p['id_profesor']
    
    # Asignaturas
    asig_res = supabase.table("Asignaturas").select("id_asignaturas, nombre").execute()
    asig_map = {normalize_text(a['nombre']): a['id_asignaturas'] for a in asig_res.data}
    
    # Grupos
    grupo_res = supabase.table("grupo").select("id_grupo, nombre").execute()
    grupo_map = {normalize_text(g['nombre']): g['id_grupo'] for g in grupo_res.data}
    
    # Aulas
    aula_res = supabase.table("aulas").select("id_aulas, nombre").execute()
    aula_map = {normalize_text(a['nombre']): a['id_aulas'] for a in aula_res.data}
    
    # Tramos
    tramo_res = supabase.table("horario_tramo").select("id_horario, horario_inicio").execute()
    tramo_map = {t['horario_inicio'][:5]: t['id_horario'] for t in tramo_res.data}
    
    return prof_map, asig_map, grupo_map, aula_map, tramo_map

def parse_csv_file(file_path, prof_map, asig_map, grupo_map, aula_map, tramo_map):
    try:
        # Intentar varias codificaciones
        for enc in ['latin-1', 'utf-8', 'cp1252']:
            try:
                with open(file_path, 'r', encoding=enc) as f:
                    content = f.read()
                break
            except:
                continue
    except Exception as e:
        print(f"Error fatal leyendo {file_path}: {e}")
        return

    lines = content.splitlines()
    if not lines: return
    
    # Identificar profesor por cabecera
    first_line = lines[0].split(';')[0].strip()
    norm_header = normalize_text(first_line)
    prof_id = prof_map.get(norm_header)
    
    if not prof_id:
        # Match parcial por cabecera
        for name_norm, pid in prof_map.items():
            if norm_header and (norm_header in name_norm or name_norm in norm_header):
                prof_id = pid
                break
                
    if not prof_id:
        # Match por nombre de archivo
        file_norm = normalize_text(os.path.basename(file_path).split('__')[0])
        for name_norm, pid in prof_map.items():
            if file_norm and (file_norm in name_norm or name_norm in file_norm):
                prof_id = pid
                break

    if not prof_id:
        print(f"  [SKIP] No se pudo identificar el profesor para {file_path}")
        return

    # Extraer mapeo de siglas a nombres completos
    materias_full_names = {}
    for line in lines:
        parts = line.split(';')
        if len(parts) >= 2 and '(' in parts[1]:
            m = re.search(r'^(.*?)\s*\((.*?)\)', parts[1].strip())
            if m:
                sigla = m.group(2).strip()
                nombre_completo = m.group(1).strip()
                materias_full_names[sigla] = nombre_completo

    # Buscar inicio de la tabla
    match_start = re.search(r';Lunes;Martes;M', content, re.IGNORECASE)
    if not match_start: return
        
    header_pos = content.rfind('\n', 0, match_start.start()) + 1
    match_end = re.search(r'Lectivas:', content)
    table_csv = content[header_pos:match_end.start()] if match_end else content[header_pos:]
        
    df = pd.read_csv(io.StringIO(table_csv), sep=';')
    df.columns = [c.strip().replace('"', '') for c in df.columns]
    
    dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
    
    count_updated = 0
    for _, row in df.iterrows():
        tramo_val = str(row.iloc[0]).strip().replace('"', '')
        if not tramo_val or tramo_val.lower() == 'nan' or 'recreo' in tramo_val.lower(): 
            continue
        
        start_time_match = re.search(r'(\d{2}:\d{2})', tramo_val)
        if not start_time_match: continue
        start_time = start_time_match.group(1)
        
        id_tramo = tramo_map.get(start_time)
        if not id_tramo: continue

        for dia_idx, dia_name in enumerate(dias):
            if dia_name not in df.columns: continue
            
            celda = str(row[dia_name]).strip()
            if not celda or celda.lower() == 'nan' or 'libre' in celda.lower() or 'recreo' in celda.lower():
                continue
                
            lines_celda = [l.strip() for l in celda.split('\n') if l.strip()]
            if not lines_celda: continue
            
            text_full = " ".join(lines_celda)
            sigla = lines_celda[0].split(' ')[0].strip()
            es_guardia = "GUARDIA" in sigla.upper()
            
            nombre_asig = materias_full_names.get(sigla, sigla)
            id_asig = asig_map.get(normalize_text(nombre_asig)) or asig_map.get(normalize_text(sigla))
            
            aula_match = re.search(r'\((\d+)\)', text_full)
            aula_txt = aula_match.group(1) if aula_match else None
            id_aula = aula_map.get(normalize_text(aula_txt))
            
            grupo_match = re.search(r'(\d.?.?\s+[A-Z]+)', text_full)
            grupo_txt = grupo_match.group(1) if grupo_match else None
            id_grupo = grupo_map.get(normalize_text(grupo_txt))

            sync_entry(prof_id, id_tramo, dia_idx + 1, id_asig, id_aula, id_grupo, es_guardia)
            count_updated += 1

    print(f"  [OK] {os.path.basename(file_path)} -> ID {prof_id} ({count_updated} tramos)")

def sync_entry(prof_id, tramo_id, dia_semana, asig_id, aula_id, grupo_id, es_guardia):
    res = supabase.table("horario")\
        .select("id_horarioss")\
        .eq("id_profesor", prof_id)\
        .eq("id_tramo", tramo_id)\
        .eq("dia_semana", dia_semana)\
        .execute()
        
    data = {
        "id_profesor": prof_id, "id_tramo": tramo_id, "dia_semana": dia_semana,
        "id_asignatura": asig_id, "id_aula": aula_id, "id_grupo": grupo_id, "es_guardia": es_guardia
    }
    
    if res.data:
        supabase.table("horario").update(data).eq("id_horarioss", res.data[0]['id_horarioss']).execute()
    else:
        supabase.table("horario").insert(data).execute()

def main():
    print("Iniciando sincronización completa...")
    prof_map, asig_map, grupo_map, aula_map, tramo_map = get_lookup_maps()
    
    # OPCIONAL: Limpiar tabla para evitar basura de runs anteriores fallidos
    # print("Limpiando tabla horario...")
    # supabase.table("horario").delete().neq("id_horarioss", 0).execute()
    
    csv_files = glob.glob("assets/csv/*.csv")
    for f in csv_files:
        basename = os.path.basename(f)
        if any(c.isalpha() for c in basename[:3]):
             parse_csv_file(f, prof_map, asig_map, grupo_map, aula_map, tramo_map)

if __name__ == "__main__":
    main()
