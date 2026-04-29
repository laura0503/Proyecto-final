import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get('URL')
key = os.environ.get('KEY')
supabase: Client = create_client(url, key)

tables = ['horario', 'profesores', 'aulas', 'Asignaturas', 'grupo', 'horario_tramo']

for table in tables:
    try:
        res = supabase.from_(table).select('*').limit(1).execute()
        if res.data:
            print(f"Table: {table}")
            print(f"Columns: {list(res.data[0].keys())}")
            print("-" * 20)
        else:
            # If no data, try to get column names some other way or just report empty
            print(f"Table: {table} (Empty)")
            # Try to fetch schema info if possible, but usually select * on empty table might not give keys
    except Exception as e:
        print(f"Error checking {table}: {e}")
