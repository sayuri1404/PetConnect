import asyncio
from paw_api.database import init_db, close_db, get_db_conn
from paw_api.config import PAW_SCHEMA
import os
from dotenv import load_dotenv

load_dotenv("paw_api/.env")

async def check():
    await init_db()
    conn_gen = get_db_conn()
    conn = await anext(conn_gen)
    try:
        tables = ["usuario_auth", "adoptante", "fundacion", "solicitud_adopcion", "mascota_rescatada"]
        print(f"Checking schema: {PAW_SCHEMA}")
        for t in tables:
            exists = await conn.fetchval(
                "SELECT to_regclass($1::text)", 
                f"{PAW_SCHEMA}.{t}"
            )
            print(f"Table {t}: {'OK' if exists else 'MISSING'}")
    finally:
        await close_db()

if __name__ == "__main__":
    asyncio.run(check())
