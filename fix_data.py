import asyncio
from paw_api.database import init_db, close_db, get_db_conn
from paw_api.config import PAW_SCHEMA
from passlib.context import CryptContext
import logging

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def fix_data():
    await init_db()
    conn_gen = get_db_conn()
    conn = await anext(conn_gen)
    
    try:
        print("--- Fixing Data ---")

        # 1. Fix Foundation 2 Password (set to '1234')
        pw_hash = pwd_context.hash("1234")
        await conn.execute(f"""
            UPDATE {PAW_SCHEMA}.usuario_auth 
            SET password_hash = $1 
            WHERE email = 'fundacion2@pawrescue.com'
        """, pw_hash)
        print("Updated fundacion2 password to '1234'.")

        # 2. Get Max Pet ID to debug
        row = await conn.fetchrow(f"SELECT MAX(id_mascota) as max_id FROM {PAW_SCHEMA}.mascota_rescatada")
        print(f"Current Max Pet ID: {row['max_id']}")

        # 3. Data for Query 4: Personas que han adoptado más de 1 mascota
        # Find an adoptante
        adoptante = await conn.fetchrow(f"SELECT id_adoptante FROM {PAW_SCHEMA}.adoptante LIMIT 1")
        if adoptante:
            aid = adoptante['id_adoptante']
            # Find 2 available pets or already adopted ones?
            # Let's insert fake adoptions for this user to ensure they have > 1
            # We need pets. Let's create dummy pets if needed, or link existing.
            # Ideally, find pets not adopted.
            
            # Insert dummy adoptions (using existing pets if possible, or creating dummy IDs if FK allows? No, FK fails)
            # Find 2 pets
            pets = await conn.fetch(f"SELECT id_mascota FROM {PAW_SCHEMA}.mascota_rescatada LIMIT 2")
            if len(pets) >= 2:
                for p in pets:
                    # Check if adopted
                    exists = await conn.fetchrow(f"SELECT 1 FROM {PAW_SCHEMA}.adopcion WHERE id_mascota = $1", p['id_mascota'])
                    if not exists:
                         # Create request first (required by FK)
                        sid_row = await conn.fetchrow(f"""
                            INSERT INTO {PAW_SCHEMA}.solicitud_adopcion (id_adoptante, id_mascota, estado)
                            VALUES ($1, $2, 'adoptada')
                            ON CONFLICT (id_adoptante, id_mascota) DO UPDATE SET estado='adoptada'
                            RETURNING id_solicitud
                        """, aid, p['id_mascota'])
                        sid = sid_row['id_solicitud']

                        await conn.execute(f"""
                            INSERT INTO {PAW_SCHEMA}.adopcion (id_solicitud, id_adoptante, id_mascota, fecha_adopcion)
                            VALUES ($1, $2, $3, CURRENT_DATE)
                            ON CONFLICT (id_mascota) DO NOTHING
                        """, sid, aid, p['id_mascota'])
                print(f"Ensured adoptante {aid} has multiple adoptions (if pets available).")

        # 4. Data for Query 6: Visitantes que vendrán HOY
        # Insert a cita_visita for TODAY
        # Need a solicitud
        sol = await conn.fetchrow(f"SELECT id_solicitud FROM {PAW_SCHEMA}.solicitud_adopcion LIMIT 1")
        if sol:
            await conn.execute(f"""
                INSERT INTO {PAW_SCHEMA}.cita_visita (id_solicitud, fecha_hora, estado)
                VALUES ($1, NOW(), 'programada')
            """, sol['id_solicitud'])
            print("Inserted cita_visita for today.")

        # 5. Data for Query 8: Cuidadores que han venido TODOS los días de la semana
        # Find a caregiver
        cuidador = await conn.fetchrow(f"SELECT id_empleado FROM {PAW_SCHEMA}.cuidadores LIMIT 1")
        if cuidador:
            eid = cuidador['id_empleado']
            # Loop last 7 days including today
            from datetime import datetime, timedelta
            today = datetime.now().date()
            for i in range(7):
                d = today - timedelta(days=i)
                await conn.execute(f"""
                    INSERT INTO {PAW_SCHEMA}.asistencia (id_empleado, fecha, estatus, hora_entrada, hora_salida)
                    VALUES ($1, $2, 'asistio', '09:00:00', '17:00:00')
                    ON CONFLICT (id_empleado, fecha) DO UPDATE SET estatus='asistio'
                """, eid, d)
            print(f"Ensured caregiver {eid} has 7 days attendance.")

    finally:
        await close_db()

if __name__ == "__main__":
    asyncio.run(fix_data())
