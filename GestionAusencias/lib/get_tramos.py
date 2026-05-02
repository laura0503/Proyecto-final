import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get('URL')
key = os.environ.get('KEY')
supabase: Client = create_client(url, key)

def get_tramos():
    try:
        res = supabase.from_('horario_tramo').select('*').order('horario_inicio').execute()
        for row in res.data:
            print(f"{row['horario_inicio']} - {row['horario_fin']} | {row['texto']} | recreo: {row['recreo']}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_tramos()
