import os
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

ID_PROFE = 154
FILE_PATH = "assets/csv/Ib__ez_Porcel__Pablo_13.csv"

def normalize_text(text):
    if not text:
        return ""
    text = str(text).strip().upper()
    # Eliminar acentos y caracteres raros
    text = "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )
    # Dejar solo letras, números y espacios básicos
    text = re.sub(r'[^A-Z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def get_id(table, column, value):
    """Busca un ID con normalización para asegurar el match."""
    if not value or pd.isna(value) or str(value).strip() == "" or str(value).lower() == "nan": 
        return None
    
    val_norm = normalize_text(value)
    
    id_map = {
        "profesores": "id_profesor",
        "Asignaturas": "id_asignaturas",
        "grupo": "id_grupo",
        "aulas": "id_aulas"
    }
    id_col = id_map.get(table)
    
    res = supabase.table(table).select(id_col, column).execute()
    
    for row in res.data:
        row_val = str(row[column])
        if normalize_text(row_val) == val_norm:
            return row[id_col]
            
    return None

def main():
    print(f"--- Cargando horario para Pablo Ibáñez (ID {ID_PROFE}) ---")
    
    try:
        with open(FILE_PATH, 'r', encoding='latin-1') as f:
            content = f.read()
            
        # Extraer la parte de la tabla
        match_start = re.search(r';Lunes;Martes;M', content, re.IGNORECASE)
        if not match_start:
            print("ERROR: No se encontró la cabecera de la tabla.")
            return
            
        header_pos = content.rfind('\n', 0, match_start.start()) + 1
        match_end = re.search(r'Lectivas:', content)
        table_csv = content[header_pos:match_end.start()]
        
        # Parsear con pandas
        df = pd.read_csv(io.StringIO(table_csv), sep=';')
        df.columns = [c.strip().replace('"', '') for c in df.columns]
        
        # Mapeo de tramos horarios
        tramos_map = {
            "16:00": 1,
            "17:00": 2,
            "18:00": 3,
            "19:15": 5,
            "20:10": 6,
            "21:05": 7
        }
        
        dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
        
        # Mapeo de materias (Sigla -> Nombre Completo)
        materias_map = {}
        lines = content.splitlines()
        for line in lines:
            parts = line.split(';')
            if len(parts) >= 2 and '(' in parts[1]:
                m = re.search(r'^(.*?)\s*\((.*?)\)', parts[1].strip())
                if m:
                    materias_map[m.group(2).strip()] = m.group(1).strip()

        # Limpiar registros previos de este profesor para evitar duplicados en la prueba
        print("Limpiando horario previo de Pablo...")
        supabase.table("horario").delete().eq("id_profesor", ID_PROFE).execute()

        count = 0
        for _, row in df.iterrows():
            # El tramo suele venir como "16:00\n17:00" en el CSV
            tramo_raw = str(row.iloc[0]).split('\n')[0].strip().replace('"', '')
            id_tramo = tramos_map.get(tramo_raw)
            
            if not id_tramo:
                continue
                
            for idx, dia in enumerate(dias):
                if dia not in df.columns: continue
                
                celda = str(row[dia]).strip()
                if not celda or celda.lower() == "nan" or "recreo" in celda.lower():
                    continue
                
                # Procesar celda
                lineas_celda = celda.split('\n')
                sigla = lineas_celda[0].split(' ')[0].strip()
                es_guardia = "GUARDIA" in sigla.upper()
                
                nombre_asig = materias_map.get(sigla, sigla)
                id_asig = get_id("Asignaturas", "nombre", nombre_asig)
                
                # Aula: suele estar entre paréntesis (203)
                aula_match = re.search(r'\((\d+)\)', celda)
                aula_txt = aula_match.group(1) if aula_match else None
                id_aula = get_id("aulas", "nombre", aula_txt) if aula_txt else None
                
                # Grupo: buscamos patrones como 1º DAM o 2º DAM
                grupo_match = re.search(r'(\d.?.?\s+\w+)', celda)
                grupo_txt = grupo_match.group(1) if grupo_match else None
                id_grupo = get_id("grupo", "nombre", grupo_txt) if grupo_txt else None

                # Inserción
                try:
                    supabase.table("horario").insert({
                        "id_profesor": ID_PROFE,
                        "id_tramo": id_tramo,
                        "id_asignatura": id_asig,
                        "id_grupo": id_grupo,
                        "id_aula": id_aula,
                        "es_guardia": es_guardia,
                        "dia_semana": idx + 1
                    }).execute()
                    count += 1
                    print(f"  [OK] {dia} {tramo_raw}: {nombre_asig} ({grupo_txt or '---'})")
                except Exception as e:
                    print(f"  [ERROR] Al insertar {dia} {tramo_raw}: {e}")

        print(f"\n--- PROCESO FINALIZADO ---")
        print(f"Se han cargado {count} registros para Pablo Ibáñez.")
        
    except Exception as e:
        print(f"ERROR CRÍTICO: {e}")

if __name__ == "__main__":
    main()
