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
    # Eliminar acentos y poner en mayúsculas
    text = str(text).strip().upper()
    text = "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )
    # Reemplazar caracteres extraños que suelen venir de fallos de encoding
    text = text.replace("", "A").replace("", "E").replace("", "I").replace("", "O").replace("", "U").replace("", "N")
    # Limpiar espacios extraños
    text = re.sub(r'\s+', ' ', text)
    return text

def get_id_fuzzy(table, column, value):
    """Busca un ID con normalización."""
    if not value or pd.isna(value) or str(value).strip() == "" or str(value).lower() == "nan": 
        return None
    
    val_norm = normalize_text(value)
    
    # Ajuste para la tabla Asignaturas (id_asignaturas)
    id_col = f"id_{table.lower()}" if table.lower() != "asignaturas" else "id_asignaturas"
    
    # Obtenemos todos para comparar localmente (más seguro con encodings rotos)
    res = supabase.table(table).select(id_col, column).execute()
    
    for row in res.data:
        if normalize_text(row[column]) == val_norm:
            return row[id_col]
            
    # Intento de búsqueda parcial si es Asignatura
    if table.lower() == "asignaturas":
        for row in res.data:
            if val_norm in normalize_text(row[column]) or normalize_text(row[column]) in val_norm:
                return row[id_col]

    return None

def get_tramo_id_by_time(time_str):
    """Mapea '16:00 17:00' -> id_tramo."""
    times = re.findall(r'(\d{2}:\d{2})', time_str)
    if len(times) < 2:
        return None
    
    start_time = times[0] + ":00"
    
    res = supabase.table("horario_tramo").select("id_horario").eq("horario_inicio", start_time).execute()
    if res.data:
        return res.data[0]["id_horario"]
    return None

def parse_materias_section(lines):
    """Extrae el mapeo de siglas a nombres completos del final del CSV."""
    mapping = {}
    in_section = False
    for line in lines:
        if "Materias" in line:
            in_section = True
            continue
        if in_section:
            parts = line.split(';')
            if len(parts) >= 2:
                # Ejemplo: "  7;APLICACIONES OFIMÁTICAS (APLOF);;;1º SMR;"
                match = re.search(r'^(.*?)\s*\((.*?)\)', parts[1].strip())
                if match:
                    full_name = match.group(1).strip()
                    acronym = match.group(2).strip()
                    mapping[acronym] = full_name
    return mapping

def procesar_un_archivo(ruta_archivo):
    print(f"\n--- Procesando: {os.path.basename(ruta_archivo)} ---")
    
    try:
        # Intentar leer con latin-1 primero
        with open(ruta_archivo, 'r', encoding='latin-1') as f:
            lineas = f.readlines()
        
        nombre_profe = lineas[0].split(';')[0].strip()
        print(f"Profesor detectado: {nombre_profe}")
        
        # Mapeo local de materias
        materias_map = parse_materias_section(lineas)
        print(f"Mapeo de materias extraído: {materias_map}")

        # Reconstruir el CSV para pandas saltando cabeceras basura
        csv_body = []
        for line in lineas:
            if ";" in line and not any(x in line for x in ["Lectivas", "Materias", "recreo"]):
                csv_body.append(line)
        
        df = pd.read_csv(io.StringIO("".join(csv_body)), sep=';')
        
        # 1. Buscar ID del Profesor
        id_profe = get_id_fuzzy("profesores", "nombre", nombre_profe)
        if not id_profe:
            print(f"❌ Error: El profesor '{nombre_profe}' no existe en la DB. Saltando.")
            return

        # Limpiar tabla de horarios previa para este profe si se desea (opcional)
        # supabase.table("horario").delete().eq("id_profesor", id_profe).execute()

        dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]

        count = 0
        for _, row in df.iterrows():
            tramo_raw = str(row.iloc[0]).strip()
            if not tramo_raw or "recreo" in tramo_raw.lower() or tramo_raw == "nan":
                continue
                
            id_tramo = get_tramo_id_by_time(tramo_raw)
            if not id_tramo:
                # Intentar búsqueda por texto exacto si falla por tiempo
                id_tramo = get_id_fuzzy("horario_tramo", "texto", tramo_raw)
                if not id_tramo:
                    print(f"⚠️ No se encontró tramo para: {tramo_raw}")
                    continue

            for idx, dia in enumerate(dias):
                if dia not in df.columns: continue
                celda = str(row[dia])
                if celda.lower() == "nan" or not celda.strip():
                    continue
                
                # Descomponer celda: Asignatura \n Grupo \n Aula
                partes = [p.strip() for p in celda.split('\n') if p.strip()]
                if not partes:
                    # A veces la celda tiene saltos de línea raros detectados por el parser
                    partes = [p.strip() for p in celda.split('\\n') if p.strip()]
                
                asignatura_raw = partes[0]
                # Limpiar el nombre de la asignatura si trae el grupo pegado (ej: APLOF 1º SMR)
                asignatura_sigla = asignatura_raw.split(' ')[0] 
                
                # Buscar nombre completo en nuestro mapa local
                asignatura_nombre = materias_map.get(asignatura_sigla, asignatura_raw)
                
                id_asig = get_id_fuzzy("Asignaturas", "nombre", asignatura_nombre)
                
                grupo_txt = partes[1] if len(partes) > 1 else None
                aula_txt = partes[2].replace('(', '').replace(')', '') if len(partes) > 2 else None
                
                # Si no hay aula/grupo en las líneas siguientes, intentar extraer del texto
                if not aula_txt:
                    aula_match = re.search(r'\((\d+)\)', celda)
                    if aula_match:
                        aula_txt = aula_match.group(1)
                
                es_guardia = "GUARDIA" in asignatura_raw.upper()

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
        
        print(f"✅ Se insertaron {count} registros para '{nombre_profe}'.")

    except Exception as e:
        print(f"❌ Error crítico en {ruta_archivo}: {e}")
        import traceback
        traceback.print_exc()

# --- INICIO ---
# Solo procesamos a Sergio por ahora para probar
archivos = glob.glob("assets/csv/*Sergio*.csv")
for archivo in archivos:
    procesar_un_archivo(archivo)

print("\n🚀 PROCESO FINALIZADO.")
