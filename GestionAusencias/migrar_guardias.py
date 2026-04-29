import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
supabase = create_client(os.environ['URL'], os.environ['KEY'])

# 1. Buscar la asignatura "GUARDIA"
asigs = supabase.table('Asignaturas').select('id_asignatura, nombre').execute().data
guardia_ids = [a['id_asignatura'] for a in asigs if a['nombre'].strip().upper() == 'GUARDIA']
print(f'Asignaturas GUARDIA encontradas: {guardia_ids}')

if not guardia_ids:
    print('No se encontró la asignatura GUARDIA. Comprobando con LIKE...')
    asigs2 = supabase.table('Asignaturas').select('id_asignatura, nombre').ilike('nombre', '%guardia%').execute().data
    print(f'  Coincidencias: {asigs2}')
    guardia_ids = [a['id_asignatura'] for a in asigs2]

if not guardia_ids:
    print('No hay asignatura GUARDIA en la tabla. Saliendo.')
    exit()

# 2. Marcar es_guardia=true en los horarios que usen esa asignatura
for gid in guardia_ids:
    r = supabase.table('horario') \
        .update({'es_guardia': True, 'id_asignatura': None}) \
        .eq('id_asignatura', gid) \
        .execute()
    print(f'  Horarios actualizados con id_asignatura={gid}: {len(r.data)}')

# 3. Eliminar la asignatura GUARDIA
for gid in guardia_ids:
    supabase.table('Asignaturas').delete().eq('id_asignatura', gid).execute()
    print(f'  Asignatura id={gid} eliminada')

# 4. Verificación final
total = supabase.table('horario').select('id_horario', count='exact').execute()
guardias = supabase.table('horario').select('id_horario', count='exact').eq('es_guardia', True).execute()
print(f'\n=== RESULTADO ===')
print(f'Total horarios: {total.count}')
print(f'Con es_guardia=true: {guardias.count}')
