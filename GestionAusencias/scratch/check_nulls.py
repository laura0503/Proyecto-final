import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

res = supabase.table("horario").select("*").execute()
total = len(res.data)
null_asig = sum(1 for r in res.data if r['id_asignatura'] is None)
null_grupo = sum(1 for r in res.data if r['id_grupo'] is None)
null_aula = sum(1 for r in res.data if r['id_aula'] is None)

print(f"Total records: {total}")
print(f"Records with NULL id_asignatura: {null_asig}")
print(f"Records with NULL id_grupo: {null_grupo}")
print(f"Records with NULL id_aula: {null_aula}")

# Mostrar algunos ejemplos de fallos
if null_asig > 0:
    print("\nEjemplos de registros sin asignatura:")
    # Re-consultar para ver qué está fallando (esto requeriría saber qué se intentó insertar, pero no lo tenemos en la DB)
    # Podemos intentar inferir de los datos actuales si hay algo obvio.
