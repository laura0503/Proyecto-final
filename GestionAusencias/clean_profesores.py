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

res = requests.get(f"{url}/rest/v1/profesores", headers=headers)
items = res.json()
deleted = 0
for p in items:
    nom = p['nombre']
    if ';' in nom:
        pid = p['id_profesor']
        print(f"Borrando profesor fantasma: '{nom}' (ID {pid})")
        # Quitar los horarios apuntados a la version sucia porque no sirven
        requests.delete(f"{url}/rest/v1/horario?id_profesor=eq.{pid}", headers=headers)
        # Borrar al profesor
        requests.delete(f"{url}/rest/v1/profesores?id_profesor=eq.{pid}", headers=headers)
        deleted += 1

print(f"Total profesores borrados: {deleted}")
