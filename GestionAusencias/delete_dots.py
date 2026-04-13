import os
import sys
import requests
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("URL")
key = os.environ.get("KEY")

headers = {
    "apikey": key,
    "Authorization": f"Bearer {key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

res = requests.get(f"{url}/rest/v1/Asignaturas", headers=headers)
items = res.json()
deleted = 0
for i in items:
    nom = i['nombre']
    if nom.replace('.', '').strip() == '':
        aid = i['id_asignaturas']
        requests.patch(f"{url}/rest/v1/horario?id_asignatura=eq.{aid}", headers=headers, json={"id_asignatura": None})
        requests.delete(f"{url}/rest/v1/Asignaturas?id_asignaturas=eq.{aid}", headers=headers)
        print(f"Borrando asignatura basura: '{nom}' (ID {aid})")
        deleted += 1

print(f"Total borradas: {deleted}")
