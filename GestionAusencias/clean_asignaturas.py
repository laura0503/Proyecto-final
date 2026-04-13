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

res = requests.get(f"{url}/rest/v1/Asignaturas?select=*", headers=headers)
asignaturas = res.json()

basura_ids = []
for a in asignaturas:
    aid = a['id_asignaturas']
    nom = a['nombre'].strip()
    upper = nom.upper()
    
    is_basura = False
    
    if ';' in nom:
        is_basura = True
    elif re.match(r'^\d{1,2}:\d{2}', nom):
        is_basura = True
    elif nom.isdigit():
        is_basura = True
    elif upper in ['RECREO', 'GUARDIA', 'LECTIVAS', 'VARIOS'] or re.sub(r'[\-\_\.]', '', nom).strip() == '':
        is_basura = True
        
    if is_basura:
        print(f"Borrando {nom}...")
        basura_ids.append(aid)

if basura_ids:
    print(f"Borrando {len(basura_ids)} asignaturas basura...")
    for aid in basura_ids:
        # Poner a null en horario
        payload = {"id_asignatura": None}
        requests.patch(f"{url}/rest/v1/horario?id_asignatura=eq.{aid}", headers=headers, json=payload)
        requests.delete(f"{url}/rest/v1/Asignaturas?id_asignaturas=eq.{aid}", headers=headers)
    print("Purga de asignaturas completada.")
else:
    print("No se encontraron asignaturas basura.")
