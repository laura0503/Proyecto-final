import os
import io
import glob
import re
import pandas as pd
import unicodedata
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def clean_text(text):
    if not text: return ""
    # Quitar posibles BOM y espacios
    text = text.replace('\ufeff', '').strip()
    return text

def normalizar(texto):
    if not texto: return ""
    s = str(texto).strip().upper()
    s = "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
    return re.sub(r'[^A-Z0-9]', '', s)

def audit_and_fix():
    print("--- INICIANDO AUDITORÍA Y ACTUALIZACIÓN ---")
    
    # 1. Datos actuales
    db_asignaturas_data = supabase.table("Asignaturas").select("*").execute().data
    db_grupos_data = supabase.table("grupo").select("*").execute().data
    
    db_asig_norm = {normalizar(r['nombre']): r['id_asignaturas'] for r in db_asignaturas_data}
    db_grupos_norm = {normalizar(r['nombre']): r['id_grupo'] for r in db_grupos_data}
    
    missing_asig = {} # normalizado -> nombre_real
    missing_grupos = {} # normalizado -> nombre_real
    
    archivos = glob.glob("assets/csv/*.csv")
    
    for ruta in archivos:
        try:
            try:
                with open(ruta, 'r', encoding='utf-8') as f:
                    lineas = f.readlines()
            except UnicodeDecodeError:
                with open(ruta, 'r', encoding='latin-1') as f:
                    lineas = f.readlines()
            
            materias_map = {}
            for l in lineas:
                if '(' in l and ';' in l:
                    m = re.search(r'([^(;]+)\s*\(([^)]+)\)', l)
                    if m:
                        nombre_completo = clean_text(m.group(1))
                        sigla = clean_text(m.group(2))
                        if len(sigla) < 10:
                            materias_map[sigla] = nombre_completo
            
            # Buscar cabecera
            inicio_tabla = 0
            for i, l in enumerate(lineas):
                if ";Lunes" in l or "Lunes;" in l:
                    inicio_tabla = i
                    break
            
            cuerpo = "".join(lineas[inicio_tabla:])
            cuerpo = re.sub(r'\n\s*\n', '\n', cuerpo)
            df = pd.read_csv(io.StringIO(cuerpo), sep=';')
            df.columns = [c.strip() for c in df.columns]

            dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]
            for _, fila in df.iterrows():
                for dia_nom in dias:
                    if dia_nom not in df.columns: continue
                    celda = str(fila[dia_nom]).strip()
                    if not celda or celda.lower() in ['nan', 'libre', 'recreo', '']: continue

                    # Aula
                    aula_match = re.search(r'\((\d+)\)', celda)
                    
                    # Grupos
                    grupos_raw = re.findall(r'(\dº?\s+[A-Z0-9\s\-]+)', celda)
                    for g in grupos_raw:
                        g_clean = clean_text(g)
                        if normalizar(g_clean) not in db_grupos_norm:
                            missing_grupos[normalizar(g_clean)] = g_clean
                    
                    # Asignatura
                    asig_limpia = celda
                    if aula_match: asig_limpia = asig_limpia.replace(aula_match.group(0), "")
                    for g in grupos_raw: asig_limpia = asig_limpia.replace(g, "")
                    
                    asig_raw = clean_text(asig_limpia.split('\n')[0].strip())
                    asig_raw = re.sub(r'[^A-Z0-9]$', '', asig_raw).strip()
                    
                    if asig_raw and "GUARDIA" not in asig_raw.upper():
                        if normalizar(asig_raw) not in db_asig_norm:
                            missing_asig[normalizar(asig_raw)] = asig_raw
                        
                        full_name = materias_map.get(asig_raw)
                        if full_name and normalizar(full_name) not in db_asig_norm:
                            missing_asig[normalizar(full_name)] = full_name

        except Exception as e:
            pass

    print(f"\nAsignaturas a añadir: {list(missing_asig.values())}")
    print(f"Grupos a añadir: {list(missing_grupos.values())}")

    # 3. Añadir (Opcional, pero el usuario pidió actualizar)
    for nombre in missing_asig.values():
        try:
            supabase.table("Asignaturas").insert({"nombre": nombre}).execute()
            print(f"Añadida asignatura: {nombre}")
        except: pass

    for nombre in missing_grupos.values():
        try:
            supabase.table("grupo").insert({"nombre": nombre}).execute()
            print(f"Añadido grupo: {nombre}")
        except: pass

if __name__ == "__main__":
    audit_and_fix()
