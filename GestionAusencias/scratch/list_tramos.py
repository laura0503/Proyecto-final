
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get('URL')
key = os.environ.get('KEY')
supabase = create_client(url, key)

def list_tramos():
    res = supabase.table('horario_tramo').select('*').execute()
    for r in res.data:
        print(f"ID {r['id_horario']} | {r['horario_inicio']} - {r['horario_fin']}")

if __name__ == "__main__":
    list_tramos()
