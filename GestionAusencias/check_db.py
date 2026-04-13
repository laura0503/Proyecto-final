import os
import asyncio
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get('URL')
key = os.environ.get('KEY')
supabase: Client = create_client(url, key)

tables = ['horario', 'profesores', 'aulas', 'Asignaturas', 'grupo', 'horario_tramo', 'horario_aula']

def check_tables():
    for table in tables:
        try:
            print(f"Checking table: {table}")
            res = supabase.from_(table).select('*', count='exact').limit(1).execute()
            count = res.count
            print(f"  - Count: {count}")
            if count > 0:
                print(f"  - First row columns: {list(res.data[0].keys())}")
        except Exception as e:
            if "does not exist" in str(e):
                print(f"  - Table '{table}' does not exist.")
            else:
                print(f"  - Error checking '{table}': {e}")
        print("-" * 20)

if __name__ == "__main__":
    check_tables()
