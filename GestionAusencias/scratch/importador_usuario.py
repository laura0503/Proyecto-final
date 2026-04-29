import os
import io
import re
import sys
import unicodedata
import pandas as pd
from supabase import create_client, Client
from dotenv import load_dotenv

# --- CONFIGURACIÓN DE ENTORNO ---
load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase: Client = create_client(URL, KEY)

# Auditoría de procesos
STATS = {'movidos': 0, 'añadidos': 0, 'actualizados': 0, 'errores': 0}

# Mapeo de siglas (CSV) a nombres reales (DB) para asegurar relaciones perfectas
ALIAS_MAP = {
    "SIOPM": "SOM", "SIOPR": "SERRE", "BIGECA": "BIOLOGÍA Y GEOLOGÍA", 
    "ANAP": "ANATOMÍA APLICADA", "SINF": "SISTEMAS INFORMÁTICOS",
    "GEOG": "GEOGRAFÍA", "HMCO": "HISTORIA DEL MUNDO COMTEMPORÁNEO",
    "LCL I": "LENGUA CASTELLANA Y LITERATURA I", "LCL II": "LENGUA CASTELLANA Y LITERATURA II",
    "APLWE": "APLICACIONES WEB", "ENDES": "ENTORNOS DE DESARROLLO"
}

# --- HERRAMIENTAS DE DESARROLLADOR SENIOR ---

def normalizar(texto):
    """Normalización para búsqueda robusta: sin acentos, mayúsculas, sin espacios extra."""
    if not texto: return ""
    texto = str(texto).strip().upper()
    texto = "".join(c for c in unicodedata.normalize("NFD", texto) if unicodedata.category(c) != "Mn")
    return re.sub(r'[^A-Z0-9]', '', texto)

def buscar_id_maestro(tabla, valor):
    """Buscador inteligente de IDs en tablas maestros."""
    if not valor or str(valor).lower() in ['nan', 'none', '']: return None
    
    id_col = {
        "profesores": "id_profesor", "Asignaturas": "id_asignaturas", 
        "grupo": "id_grupo", "aulas": "id_aulas", "horario_tramo": "id_horario"
    }.get(tabla)

    try:
        res = supabase.table(tabla).select("*").execute()
        val_norm = normalizar(valor)
        
        # 1. Match Exacto (Normalizado)
        for row in res.data:
            if normalizar(row.get('nombre') or row.get('horario_inicio')) == val_norm:
                return row[id_col]
        
        # 2. Match para Aulas (Numérico)
        if tabla == "aulas":
            val_digit = re.sub(r'\D', '', valor)
            if val_digit:
                for row in res.data:
                    if val_digit in str(row.get('nombre')):
                        return row[id_col]

        # 3. Match Parcial (Para asignaturas largas)
        if tabla in ["Asignaturas", "profesores"]:
            for row in res.data:
                db_norm = normalizar(row.get('nombre'))
                if (len(db_norm) > 3 and db_norm in val_norm) or (len(val_norm) > 3 and val_norm in db_norm):
                    return row[id_col]
        
        return None
    except Exception as e:
        print(f"Error en consulta {tabla}: {e}")
        return None

def upsert_incremental(p_id, dia, t_id, asig_id, g_id, a_id, es_guardia):
    """Lógica de reparación: UPDATE si falta info, INSERT si no existe."""
    try:
        # Buscamos si ya existe la combinación única de hueco
        res = supabase.table("horario").select("*")\
            .eq("id_profesor", p_id)\
            .eq("dia_semana", dia)\
            .eq("id_tramo", t_id).execute()
        
        if res.data:
            # Existe: Verificamos si podemos mejorar la información (completar NULLs)
            row = res.data[0]
            update_fields = {}
            if not row.get('id_asignatura') and asig_id: update_fields['id_asignatura'] = asig_id
            if not row.get('id_aula') and a_id: update_fields['id_aula'] = a_id
            if not row.get('id_grupo') and g_id: update_fields['id_grupo'] = g_id
            
            if update_fields:
                supabase.table("horario").update(update_fields).eq("id_horarioss", row['id_horarioss']).execute()
                STATS['actualizados'] += 1
        else:
            # No existe: Inserción limpia
            supabase.table("horario").insert({
                "id_profesor": p_id, "dia_semana": dia, "id_tramo": t_id,
                "id_asignatura": asig_id, "id_grupo": g_id, "id_aula": a_id,
                "es_guardia": es_guardia
            }).execute()
            STATS['añadidos'] += 1
    except Exception as e:
        print(f"Error sincronizando registro: {e}")
        STATS['errores'] += 1

# --- PROCESO DE SINCRONIZACIÓN CSV ---

def sincronizar_csv(folder_path):
    print(f"--- INICIANDO SINCRONIZACIÓN BACKEND ---")
    archivos = [os.path.join(folder_path, f) for f in os.listdir(folder_path) if f.endswith('.csv')]
    
    for ruta in archivos:
        try:
            with open(ruta, 'r', encoding='utf-8', errors='ignore') as f:
                lineas = f.readlines()
            if len(lineas) < 2: continue

            # 1. Identificar Profesor del Header
            header = lineas[0].split(';')[0].strip().replace('"', '')
            p_id = buscar_id_maestro("profesores", header)
            if not p_id: continue

            print(f"Sincronizando: {header}")

            # 2. Localizar inicio de tabla (Lunes)
            start_idx = 1
            for i, l in enumerate(lineas):
                if ";Lunes" in l or "Lunes;" in l:
                    start_idx = i
                    break
            
            # 3. Procesar datos con Pandas para estabilidad
            cuerpo = "".join(lineas[start_idx:])
            df = pd.read_csv(io.StringIO(cuerpo), sep=';')
            df.columns = [c.strip() for c in df.columns]
            dias_cols = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]

            tramo_count = 0
            for _, fila in df.iterrows():
                time_info = str(fila.iloc[0]).split('\n')[0].strip()
                if not time_info or "recreo" in time_info.lower(): continue
                
                # Mapeo determinista de tramos (1,2,3 -> Recreo -> 5,6,7)
                tramo_count += 1
                if tramo_count > 6: t_id = 7
                elif tramo_count <= 3: t_id = tramo_count
                else: t_id = tramo_count + 1
                if t_id > 7: break

                for dia_idx, dia_nom in enumerate(dias_cols):
                    if dia_nom not in df.columns: continue
                    celda = str(fila[dia_nom]).strip().replace('"', '')
                    if not celda or celda.lower() in ['nan', 'libre', '']: continue

                    # FORMATO: [0] Asignatura, [1] Grupo, [2] Aula
                    partes = [p.strip() for p in re.split(r'\\n|\n', celda) if p.strip()]
                    if not partes: continue

                    asig_raw = partes[0]
                    g_raw = partes[1] if len(partes) > 1 else None
                    a_raw = partes[2] if len(partes) > 2 else None

                    es_guardia = "GUARDIA" in asig_raw.upper()
                    asig_id = None if es_guardia else buscar_id_maestro("Asignaturas", ALIAS_MAP.get(asig_raw, asig_raw))
                    g_id = buscar_id_maestro("grupo", g_raw)
                    
                    # Limpieza de Aula: (119) -> 119
                    a_limpia = re.sub(r'[\(\)]', '', a_raw) if a_raw else None
                    a_id = buscar_id_maestro("aulas", a_limpia)

                    upsert_incremental(p_id, dia_idx + 1, t_id, asig_id, g_id, a_id, es_guardia)

        except Exception as e:
            print(f"Fallo en archivo {ruta}: {e}")

def aplicar_parches_expertos():
    """Garantiza la sincronización de casos especiales y faltantes."""
    print("\n--- APLICANDO AJUSTES DE EXPERTO ---")
    
    # Enric (Sin CSV)
    p_enric = buscar_id_maestro("profesores", "Enric")
    if p_enric:
        tramos = [(3, 5), (3, 6), (5, 1), (5, 2)]
        for d, t in tramos:
            upsert_incremental(p_enric, d, t, buscar_id_maestro("Asignaturas", "SGEMP"), 
                               buscar_id_maestro("grupo", "2º DAM"), buscar_id_maestro("aulas", "218"), False)

    # Sergio Alguacil (Mover APLOF)
    p_sergio = buscar_id_maestro("profesores", "Sergio Alguacil")
    asig_aplof = buscar_id_maestro("Asignaturas", "APLICACIONES OFIMÁTICAS")
    if p_sergio and asig_aplof:
        supabase.table("horario").update({"id_tramo": 5})\
            .eq("id_profesor", p_sergio).eq("id_asignatura", asig_aplof).eq("id_tramo", 6).execute()
        STATS['movidos'] += 1

    # Forzar SASP para Sergio
    upsert_incremental(p_sergio, 4, 1, buscar_id_maestro("Asignaturas", "SASP"), None, None, False)

def main():
    sincronizar_csv("assets/csv")
    aplicar_parches_expertos()
    
    print("\n--- SINCRONIZACIÓN FINALIZADA CON ÉXITO ---")
    print(f"Registros Añadidos: {STATS['añadidos']}")
    print(f"Registros Reparados/Actualizados: {STATS['actualizados']}")
    print(f"Registros Movidos: {STATS['movidos']}")
    print(f"Errores: {STATS['errores']}")

if __name__ == "__main__":
    main()
