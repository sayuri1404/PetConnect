import asyncio
from paw_api.database import init_db, close_db, get_db_conn
from paw_api.config import PAW_SCHEMA
import os
from dotenv import load_dotenv

load_dotenv("paw_api/.env")

async def check_users():
    await init_db()
    conn_gen = get_db_conn()
    conn = await anext(conn_gen)
    try:
        # Check users in auth table joined with fundacion
        query = f"""
        SELECT u.email, u.rol, f.nombre 
        FROM {PAW_SCHEMA}.usuario_auth u
        LEFT JOIN {PAW_SCHEMA}.fundacion f ON u.id_usuario = f.id_usuario
        WHERE u.rol = 'fundacion'
        """
        rows = await conn.fetch(query)
        if not rows:
            print("No foundation users found.")
        else:
            for r in rows:
                print(f"Email: {r['email']}, Nombre: {r['nombre']}")
    finally:
        await close_db()

if __name__ == "__main__":
    asyncio.run(check_users())
