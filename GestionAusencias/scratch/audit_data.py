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

def normalizar(texto):
    if not texto: return ""
    s = str(texto).strip().upper()
    s = "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
    return re.sub(r'[^A-Z0-9]', '', s)

def audit():
    print("--- INICIANDO AUDITORÍA DE DATOS ---")
    
    # 1. Obtener datos actuales de la DB
    db_asignaturas = {normalizar(r['nombre']): r['nombre'] for r in supabase.table("Asignaturas").select("nombre").execute().data}
    db_grupos = {normalizar(r['nombre']): r['nombre'] for r in supabase.table("grupo").select("nombre").execute().data}
    db_aulas = {normalizar(r['nombre']): r['nombre'] for r in supabase.table("aulas").select("nombre").execute().data}
    
    csv_asignaturas = set()
    csv_grupos = set()
    csv_aulas = set()
    
    archivos = glob.glob("assets/csv/*.csv")
    
    for ruta in archivos:
        try:
            try:
                with open(ruta, 'r', encoding='utf-8') as f:
                    lineas = f.readlines()
            except UnicodeDecodeError:
                with open(ruta, 'r', encoding='latin-1') as f:
                    lineas = f.readlines()
            
            if len(lineas) < 2: continue

            # Mapeo de Materias (Sigla -> Nombre Completo)
            materias_map = {}
            for l in lineas:
                if '(' in l and ';' in l:
                    m = re.search(r'([^(;]+)\s*\(([^)]+)\)', l)
                    if m:
                        nombre_completo = m.group(1).strip()
                        sigla = m.group(2).strip()
                        if len(sigla) < 10:
                            materias_map[sigla] = nombre_completo

            # Buscar cabecera de la tabla
            inicio_tabla = 1
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
                    if aula_match: csv_aulas.add(aula_match.group(1))
                    
                    # Grupos
                    grupos_raw = re.findall(r'(\dº?\s+[A-Z0-9\s\-]+)', celda)
                    for g in grupos_raw: csv_grupos.add(g.strip())
                    
                    # Asignatura
                    asig_limpia = celda
                    if aula_match: asig_limpia = asig_limpia.replace(aula_match.group(0), "")
                    for g in grupos_raw: asig_limpia = asig_limpia.replace(g, "")
                    
                    asig_raw = asig_limpia.split('\n')[0].strip()
                    asig_raw = re.sub(r'[^A-Z0-9]$', '', asig_raw).strip()
                    
                    if "GUARDIA" not in asig_raw.upper():
                        csv_asignaturas.add(asig_raw)
                        if asig_raw in materias_map:
                            csv_asignaturas.add(materias_map[asig_raw])

        except Exception as e:
            print(f"Error procesando {ruta}: {e}")

    # 2. Comparar
    missing_asignaturas = [a for a in csv_asignaturas if normalizar(a) not in db_asignaturas]
    missing_grupos = [g for g in csv_grupos if normalizar(g) not in db_grupos]
    missing_aulas = [aula for aula in csv_aulas if normalizar(aula) not in db_aulas]

    print(f"\n--- RESULTADOS ---")
    print(f"Asignaturas faltantes ({len(missing_asignaturas)}):")
    for a in sorted(missing_asignaturas): print(f"  - {a}")
    
    print(f"\nGrupos faltantes ({len(missing_grupos)}):")
    for g in sorted(missing_grupos): print(f"  - {g}")
    
    print(f"\nAulas faltantes ({len(missing_aulas)}):")
    for a in sorted(missing_aulas): print(f"  - {a}")

if __name__ == "__main__":
    audit()
