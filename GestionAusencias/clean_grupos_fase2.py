import os
import sys
import requests
import re
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

grupos_res = requests.get(f"{url}/rest/v1/grupo?select=*", headers=headers)
grupos = grupos_res.json()

basura_ids = []
for g in grupos:
    gid = g['id_grupo']
    nom = g['nombre'].strip()
    upper = nom.upper()
    
    is_basura = False
    
    # Filter 1: Contains semicolon
    if ";" in nom:
        is_basura = True
    # Filter 2: Is a timestamp like 17:00, 19:15
    elif re.match(r'^\d{1,2}:\d{2}', nom):
        is_basura = True
    
    if is_basura:
        print(f"Borrando {nom}...")
        basura_ids.append(gid)

if basura_ids:
    print(f"Borrando {len(basura_ids)} grupos basura adicionales...")
    for gid in basura_ids:
        payload = {"id_grupo": None}
        requests.patch(f"{url}/rest/v1/horario?id_grupo=eq.{gid}", headers=headers, json=payload)
        requests.delete(f"{url}/rest/v1/grupo?id_grupo=eq.{gid}", headers=headers)
    print("Purga fase 2 completada.")
else:
    print("No se encontraron esos grupos de la imagen en Supabase.")
