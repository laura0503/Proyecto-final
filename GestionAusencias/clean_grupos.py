import os
import sys
import requests
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("URL")
key = os.environ.get("KEY")

if not url or not key:
    print("Falta URL o KEY en .env")
    sys.exit(1)

headers = {
    "apikey": key,
    "Authorization": f"Bearer {key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# 1. Obtener todas las asignaturas
asig_res = requests.get(f"{url}/rest/v1/Asignaturas?select=nombre", headers=headers)
asignaturas = [r['nombre'].strip().upper() for r in asig_res.json()]

# 2. Obtener todos los profesores
prof_res = requests.get(f"{url}/rest/v1/profesores?select=nombre", headers=headers)
profesores = [r['nombre'].strip().upper() for r in prof_res.json()]
for p in list(profesores):
    parts = p.split(',')
    if len(parts) > 1:
        profesores.append(parts[0].strip().upper())
        profesores.append(parts[1].strip().upper())

# 3. Obtener todos los grupos
grupos_res = requests.get(f"{url}/rest/v1/grupo?select=*", headers=headers)
grupos = grupos_res.json()

basura_ids = []
for g in grupos:
    gid = g['id_grupo']
    nom = g['nombre'].strip()
    upper = nom.upper()
    
    is_basura = False
    
    if upper in asignaturas:
        is_basura = True
        print(f"Borrando {nom} porque es una Asignatura.")
    elif upper in profesores:
        is_basura = True
        print(f"Borrando {nom} porque es un Profesor.")
    elif upper in ['RECREO', 'GUARDIA', 'LECTIVAS', 'VARIOS', '-']:
        is_basura = True
        print(f"Borrando {nom} porque es una palabra prohibida.")
    elif nom.replace('-', '').strip() == '':
        is_basura = True
    elif nom.isdigit():
        is_basura = True
        print(f"Borrando {nom} porque es solo numeros (Aula).")
    
    if not is_basura:
        for p in profesores:
            if upper == p or (len(upper) > 5 and upper in p):
                is_basura = True
                print(f"Borrando {nom} porque coincide con prof {p}.")
                break

    if is_basura:
        basura_ids.append(gid)

if basura_ids:
    print(f"Borrando {len(basura_ids)} grupos basura...")
    for gid in basura_ids:
        payload = {"id_grupo": None}
        requests.patch(f"{url}/rest/v1/horario?id_grupo=eq.{gid}", headers=headers, json=payload)
        requests.delete(f"{url}/rest/v1/grupo?id_grupo=eq.{gid}", headers=headers)
    print("Purga completada.")
else:
    print("No se encontraron grupos basura en la DB.")
