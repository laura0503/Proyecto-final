import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
supabase = create_client(os.environ.get('URL'), os.environ.get('KEY'))

profs = supabase.table('profesores').select('id_profesor, nombre').execute().data
horarios = supabase.table('horario').select('id_profesor').execute().data
h_ids = set([r['id_profesor'] for r in horarios])

from collections import Counter
counts = Counter([r['nombre'] for r in profs])
dups = [name for name, count in counts.items() if count > 1]

print("--- REPORTE DE DISTRIBUCIÓN DE HORARIOS ---")
for name in dups:
    ids = [r['id_profesor'] for r in profs if r['nombre'] == name]
    counts = {}
    for i in ids:
        res = supabase.table('horario').select('id_profesor', count='exact').eq('id_profesor', i).execute()
        counts[i] = res.count
    print(f"Profesor: {name} -> IDs: {counts}")
