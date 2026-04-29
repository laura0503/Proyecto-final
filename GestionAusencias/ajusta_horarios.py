import os
import re
import sys
import unicodedata
from supabase import create_client, Client
from dotenv import load_dotenv

# --- CONFIGURACIÓN ---
load_dotenv()
URL = os.environ.get('URL')
KEY = os.environ.get('KEY')
supabase: Client = create_client(URL, KEY)

# Contadores para el resumen
STATS = {'movidos': 0, 'añadidos': 0, 'actualizados': 0}

# --- UTILIDADES ---

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
    
    # Búsqueda difusa para asignaturas y profesores
    if tabla in ['Asignaturas', 'profesores']:
        for row in CACHE.get(tabla, []):
            db_val = normalizar(row.get(columna_busqueda))
            if (len(val_norm) > 3 and val_norm in db_val) or (len(db_val) > 3 and db_val in val_norm):
                return row.get(id_col)
    return None

# --- OPERACIONES DE AJUSTE ---

def upsert_horario(prof_id, dia, tramo, asig_nom=None, grupo_nom=None, aula_nom=None, es_guardia=False):
    """Inserta o actualiza un registro de horario para un hueco específico."""
    asig_id = buscar_id('Asignaturas', asig_nom) if asig_nom else None
    grupo_id = buscar_id('grupo', grupo_nom) if grupo_nom else None
    aula_id = buscar_id('aulas', aula_nom) if aula_nom else None
    
    # Buscar si ya existe
    res = supabase.table("horario").select("*")\
        .eq("id_profesor", prof_id)\
        .eq("dia_semana", dia)\
        .eq("id_tramo", tramo).execute()
    
    data = {
        "id_profesor": prof_id,
        "dia_semana": dia,
        "id_tramo": tramo,
        "id_asignatura": asig_id,
        "id_grupo": grupo_id,
        "id_aula": aula_id,
        "es_guardia": es_guardia
    }

    if res.data:
        # Actualizar
        supabase.table("horario").update(data)\
            .eq("id_profesor", prof_id)\
            .eq("dia_semana", dia)\
            .eq("id_tramo", tramo).execute()
        STATS['actualizados'] += 1
    else:
        # Insertar
        supabase.table("horario").insert(data).execute()
        STATS['añadidos'] += 1

def mover_asignatura(prof_id, asig_nom, tramo_origen, tramo_destino):
    """Mueve una asignatura de un tramo a otro para todos los días que la tenga."""
    asig_id = buscar_id('Asignaturas', asig_nom)
    if not asig_id:
        print(f"Error: No se encontró la asignatura '{asig_nom}'")
        return

    print(f"Buscando '{asig_nom}' (ID: {asig_id}) para mover del tramo {tramo_origen} al {tramo_destino}...")
    res = supabase.table("horario").select("*")\
        .eq("id_profesor", prof_id)\
        .eq("id_asignatura", asig_id)\
        .eq("id_tramo", tramo_origen).execute()
    
    if not res.data:
        print(f"  No se encontraron registros de '{asig_nom}' en el tramo {tramo_origen}.")
        return

    for row in res.data:
        print(f"  Moviendo día {row['dia_semana']}...")
        # Verificar si el destino está ocupado
        dest = supabase.table("horario").select("*")\
            .eq("id_profesor", prof_id)\
            .eq("dia_semana", row['dia_semana'])\
            .eq("id_tramo", tramo_destino).execute()
        
        if dest.data:
            print(f"    Destino ocupado, actualizando...")
            supabase.table("horario").update({
                "id_asignatura": asig_id,
                "id_grupo": row['id_grupo'],
                "id_aula": row['id_aula'],
                "es_guardia": False
            }).eq("id_horarioss", dest.data[0]['id_horarioss']).execute()
            supabase.table("horario").delete().eq("id_horarioss", row['id_horarioss']).execute()
        else:
            print(f"    Destino libre, moviendo...")
            supabase.table("horario").update({"id_tramo": tramo_destino})\
                .eq("id_horarioss", row['id_horarioss']).execute()
        
        STATS['movidos'] += 1

def reimportar_profesor(nombre_prof, pattern_archivo):
    """Re-importa el horario de un profesor específico desde su CSV."""
    p_id = buscar_id('profesores', nombre_prof)
    if not p_id:
        print(f"Error: Profesor '{nombre_prof}' no encontrado para re-importación.")
        return

    print(f"\nDBA: Re-importando {nombre_prof}...")
    # Buscamos el archivo en assets/csv
    import glob
    archivos = glob.glob(f"assets/csv/*{pattern_archivo}*.csv")
    if not archivos:
        print(f"  No se encontró el archivo CSV para {pattern_archivo}")
        return
    
    with open(archivos[0], 'r', encoding='utf-8', errors='ignore') as f:
        lineas = f.readlines()
    
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
            
            asig_nom = asig_txt if not es_guardia else None
            grupo_nom = celda_parts[1] if len(celda_parts) > 1 else None
            aula_nom = celda_parts[2] if len(celda_parts) > 2 else None
            if aula_nom: aula_nom = re.sub(r'[\(\)]', '', aula_nom)

            upsert_horario(p_id, dia_idx, tramo_id, asig_nom, grupo_nom, aula_nom, es_guardia)

# --- CORRECCIONES ---

def ejecutar_ajustes():
    print("Iniciando ajustes de experto...")

    # Sergio Alguacil
    p_sergio = buscar_id('profesores', 'Alguacil Jiménez, Sergio A.')
    if p_sergio:
        mover_asignatura(p_sergio, 'APLICACIONES OFIMÁTICAS', 6, 5) # 20:10 -> 19:15
        upsert_horario(p_sergio, 4, 1, 'SOSTENIBILIDAD APLICADA SISTEMA PRODUCTIVO') # Jueves 1ª (SASP)
        upsert_horario(p_sergio, 5, 5, 'APLICACIONES OFIMÁTICAS') # Viernes tras recreo (19:15)

    # Miguel Anxo
    p_anxo = buscar_id('profesores', 'Álvarez Troncoso, Miguel Anxo')
    if p_anxo:
        upsert_horario(p_anxo, 1, 6, 'INGLÉS II')
        upsert_horario(p_anxo, 4, 6, 'INGLÉS I')

    # Miguel Bustos
    p_bustos = buscar_id('profesores', 'Bustos Rodríguez, Miguel')
    if p_bustos:
        upsert_horario(p_bustos, 1, 6, 'BIOLOGÍA Y GEOLOGÍA_CIENCIAS AMBIENTALES') # Lunes 20:10
        upsert_horario(p_bustos, 3, 5, 'BIOLOGÍA Y GEOLOGÍA_CIENCIAS AMBIENTALES') # Miércoles 19:15
        upsert_horario(p_bustos, 5, 5, 'ANATOMÍA APLICADA') # Viernes 19:15
        upsert_horario(p_bustos, 5, 6, 'BIOLOGÍA Y GEOLOGÍA_CIENCIAS AMBIENTALES')

    # Pablo Cerillo
    p_cerillo = buscar_id('profesores', 'Cerrillo Ruiz, Pablo')
    if p_cerillo:
        upsert_horario(p_cerillo, 1, 5, 'ENTORNOS DE DESARROLLO')
        upsert_horario(p_cerillo, 2, 6, 'SISTEMAS')
        upsert_horario(p_cerillo, 5, 5, 'ENTORNOS DE DESARROLLO')
        upsert_horario(p_cerillo, 5, 6, 'SEGURIDAD INFORMÁTICA')

    # Manuel Cordón
    p_cordon = buscar_id('profesores', 'Cordon Villarejo, Manuel')
    if p_cordon:
        upsert_horario(p_cordon, 5, 5, 'APLICACIONES WEB')

    # Enrique (Añadir más sesiones)
    p_enrique = buscar_id('profesores', 'Díez Cabrera, Enrique')
    if p_enrique:
        upsert_horario(p_enrique, 3, 7, 'GEOGRAFÍA')
        upsert_horario(p_enrique, 5, 7, 'HISTORIA DEL MUNDO COMTEMPORÁNEO')

    # Maria de la O
    p_lao = buscar_id('profesores', 'Durán Piña, María de la O')
    if p_lao:
        upsert_horario(p_lao, 4, 5, 'ITINERARIO PERSONAL EMPLEABILI') # Reemplaza guardia

    # Mar Fernández
    p_mar = buscar_id('profesores', 'Fernández Latorre, Mar')
    if p_mar:
        upsert_horario(p_mar, 1, 1, 'LENGUA CASTELLANA Y LITERATURA I')

    # Carmen
    p_carmen = buscar_id('profesores', 'Gómez Letrón, Carmen')
    if p_carmen:
        mover_asignatura(p_carmen, 'HISTORIA DE ESPAÑA', 6, 5)
        upsert_horario(p_carmen, 4, 5, 'HISTORIA DE ESPAÑA')

    # Rosa María
    p_rosa = buscar_id('profesores', 'Palos Cid-Fuentes, Rosa María')
    if p_rosa:
        upsert_horario(p_rosa, 4, 5, 'SISTEMAS INFORMÁTICOS')
        upsert_horario(p_rosa, 1, 5, 'SOSTENIBILIDAD APLICADA SISTEMA PRODUCTIVO')

    # Maricarmen
    p_mcarmen = buscar_id('profesores', 'Valderas Siles, María Carmen')
    if p_mcarmen:
        upsert_horario(p_mcarmen, 2, 5, 'SERVICIOS EN RED')

    # Re-importaciones generales solicitadas
    reimportar_profesor('Garcia Garzan, Raquel', 'Garc_a_Garz_n')
    reimportar_profesor('Ibañez Porcel, Pablo', 'Ib__ez_Porcel')
    reimportar_profesor('Manzano Herrero, Paloma', 'Manzano_Herrero')
    reimportar_profesor('Sanchez Palacios, Manuel', 'S_nchez_Palacios')

    # Resumen final
    print("\n--- RESUMEN DE OPERACIONES ---")
    print(f"Filas movidas: {STATS['movidos']}")
    print(f"Filas añadidas: {STATS['añadidos']}")
    print(f"Filas actualizadas: {STATS['actualizados']}")

if __name__ == "__main__":
    ejecutar_ajustes()
