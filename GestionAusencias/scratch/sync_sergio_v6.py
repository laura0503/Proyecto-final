import os
import pandas as pd
from supabase import create_client
import io
import glob
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
    # Eliminar acentos
    text = "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )
    # Dejar solo letras y números
    text = re.sub(r'[^A-Z0-9]', '', text)
    return text

def get_id_fuzzy(table, column, value):
    """Busca un ID con normalización extrema."""
    if not value or pd.isna(value) or str(value).strip() == "" or str(value).lower() == "nan": 
        return None
    
    val_norm = normalize_text(value)
    
    id_map = {
        "profesores": "id_profesor",
        "asignaturas": "id_asignaturas",
        "grupo": "id_grupo",
        "aulas": "id_aulas",
        "horario_tramo": "id_horario"
    }
    id_col = id_map.get(table.lower(), f"id_{table.lower()}")
    
    res = supabase.table(table).select(id_col, column).execute()
    
    for row in res.data:
        row_norm = normalize_text(row[column])
        if row_norm == val_norm or val_norm in row_norm or row_norm in val_norm:
            return row[id_col]
            
    return None

def get_tramo_id_by_time(time_str):
    times = re.findall(r'(\d{2}:\d{2})', str(time_str))
    if len(times) < 2: return None
    start_time = times[0] + ":00"
    res = supabase.table("horario_tramo").select("id_horario").eq("horario_inicio", start_time).execute()
    if res.data: return res.data[0]["id_horario"]
    return None

def parse_materias_section(content):
    mapping = {}
    lines = content.splitlines()
    in_section = False
    for line in lines:
        if "Materias" in line:
            in_section = True
            continue
        if in_section:
            parts = line.split(';')
            if len(parts) >= 2:
                match = re.search(r'^(.*?)\s*\((.*?)\)', parts[1].strip())
                if match: mapping[match.group(2).strip()] = match.group(1).strip()
    return mapping

def clean_csv_content(content):
    match_start = re.search(r';Lunes;Martes;M', content, re.IGNORECASE)
    if not match_start: return None
    header_pos = content.rfind('\n', 0, match_start.start()) + 1
    match_end = re.search(r'Lectivas:', content)
    end_pos = match_end.start() if match_end else len(content)
    table_content = content[header_pos:end_pos]
    def remove_newlines(m): return m.group(0).replace('\n', ' ').replace('\r', ' ')
    table_content = re.sub(r'"[^"]*"', remove_newlines, table_content, flags=re.DOTALL)
    table_content = "\n".join([l for l in table_content.splitlines() if l.strip()])
    return table_content

def procesar_un_archivo(ruta_archivo):
    print(f"\n--- Procesando: {os.path.basename(ruta_archivo)} ---")
    try:
        with open(ruta_archivo, 'r', encoding='latin-1') as f: content = f.read()
        nombre_profe = content.split(';')[0].strip()
        materias_map = parse_materias_section(content)
        table_csv = clean_csv_content(content)
        if not table_csv: return
        df = pd.read_csv(io.StringIO(table_csv), sep=';')
        df.columns = [c.strip().replace('"', '') for c in df.columns]
        id_profe = get_id_fuzzy("profesores", "nombre", nombre_profe)
        if not id_profe:
            print(f"ERROR: Profesor '{nombre_profe}' no encontrado.")
            return

        dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
        col_map = {d: c for d in dias for c in df.columns if normalize_text(d) == normalize_text(c)}

        count = 0
        for _, row in df.iterrows():
            tramo_raw = str(row.iloc[0]).strip()
            if not tramo_raw or "recreo" in tramo_raw.lower() or tramo_raw == "nan": continue
            id_tramo = get_tramo_id_by_time(tramo_raw)
            if not id_tramo: continue
            for idx, dia in enumerate(dias):
                col_name = col_map.get(dia)
                if not col_name: continue
                celda = str(row[col_name]).strip()
                if celda.lower() == "nan" or not celda or celda == "recreo": continue
                
                sigla = celda.split(' ')[0]
                nombre_asig = materias_map.get(sigla, celda)
                id_asig = get_id_fuzzy("Asignaturas", "nombre", nombre_asig)
                if not id_asig: id_asig = get_id_fuzzy("Asignaturas", "nombre", sigla)

                es_guardia = "GUARDIA" in celda.upper()
                aula_match = re.search(r'\((\d+)\)', celda)
                aula_txt = aula_match.group(1) if aula_match else None
                grupo_match = re.search(r'(\dº\s+\w+)', celda)
                grupo_txt = grupo_match.group(1) if grupo_match else None
                id_grupo = get_id_fuzzy("grupo", "nombre", grupo_txt) if grupo_txt else None
                id_aula = get_id_fuzzy("aulas", "nombre", aula_txt) if aula_txt else None

                if id_asig or es_guardia:
                    supabase.table("horario").insert({
                        "id_profesor": id_profe,
                        "id_tramo": id_tramo,
                        "id_asignatura": id_asig,
                        "id_grupo": id_grupo,
                        "id_aula": id_aula,
                        "es_guardia": es_guardia,
                        "dia_semana": idx + 1
                    }).execute()
                    count += 1
        print(f"OK: {count} registros para '{nombre_profe}'.")
    except Exception as e: print(f"ERROR: {e}")

# --- INICIO ---
for archivo in glob.glob("assets/csv/*Sergio*.csv"):
    procesar_un_archivo(archivo)
print("\nPROCESO FINALIZADO.")
