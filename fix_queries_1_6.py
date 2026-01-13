
import asyncio
import os
import random
import asyncpg
from dotenv import load_dotenv

load_dotenv("paw_api/.env")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://paw_admin:paw_pass@localhost:5433/paw_rescue")

async def fix_timezone_data():
    print(f"Connecting to {DATABASE_URL}...")
    try:
        conn = await asyncpg.connect(DATABASE_URL)
    except Exception as e:
        print(f"Error connecting: {e}")
        return

    try:
        # DATA FOR JAN 12 (User's Local Today)
        print("--- Inserting Data for 2026-01-12 (Fix Timezone Issue) ---")
        
        # 1. Rescate
        async with conn.transaction():
            pet_name = f"Mascota Ayer/Hoy {random.randint(1000,9999)}"
            mid = await conn.fetchval("""
                INSERT INTO paw.mascota_rescatada (nombre, especie_id, tamanio, sexo, id_origen, fuente)
                VALUES ($1, 1, 'mediano', 'Hembra', 1, 'fundacion')
                RETURNING id_mascota
            """, pet_name)
            
            # Explicit date: 2026-01-12
            await conn.execute("""
                INSERT INTO paw.rescate (id_mascota, fecha, alcaldia, situacion, necesidades_especiales)
                VALUES ($1, '2026-01-12', 'Miguel Hidalgo', 'Rescate Nocturno', NULL)
            """, mid)
            print(f"Inserted Pet {mid} ({pet_name}) with Rescue DATE 2026-01-12.")

        # 2. Visita
        async with conn.transaction():
            email = f"visitante{random.randint(1000,9999)}@ayer.com"
            aid = await conn.fetchval("""
                INSERT INTO paw.adoptante (nombre, email, telefono)
                VALUES ('Visitante Timezone', $1, '5555555555')
                RETURNING id_adoptante
            """, email)
            
            pet_name_visita = f"Perrito Timezone {random.randint(1000,9999)}"
            mid_v = await conn.fetchval("""
                INSERT INTO paw.mascota_rescatada (nombre, especie_id, tamanio, id_origen, fuente)
                VALUES ($1, 1, 'pequeño', 1, 'fundacion')
                RETURNING id_mascota
            """, pet_name_visita)
            
            sid = await conn.fetchval("""
                INSERT INTO paw.solicitud_adopcion (id_adoptante, id_mascota, estado)
                VALUES ($1, $2, 'pendiente')
                RETURNING id_solicitud
            """, aid, mid_v)
            
            # Explicit timestamp: 2026-01-12 18:00:00
            await conn.execute("""
                INSERT INTO paw.cita_visita (id_solicitud, fecha_hora, estado)
                VALUES ($1, '2026-01-12 18:00:00', 'programada')
            """, sid)
            print(f"Inserted Visit for request {sid} (User {aid}) for DATE 2026-01-12.")

        print("\n--- Verifying Data Distribution ---")
        rows_rescate = await conn.fetch("SELECT fecha, count(*) FROM paw.rescate WHERE fecha >= '2026-01-10' GROUP BY fecha ORDER BY fecha")
        for r in rows_rescate:
            print(f"Rescates on {r['fecha']}: {r['count']}")
            
        rows_cita = await conn.fetch("SELECT fecha_hora::date as dia, count(*) FROM paw.cita_visita WHERE fecha_hora >= '2026-01-10' GROUP BY dia ORDER BY dia")
        for r in rows_cita:
            print(f"Citas on {r['dia']}: {r['count']}")

    except Exception as e:
        print(f"Error executing logic: {e}")
    finally:
        await conn.close()
        print("\nDone.")

if __name__ == "__main__":
    asyncio.run(fix_timezone_data())
